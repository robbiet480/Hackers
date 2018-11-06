//
//  HNPost.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftSoup
import Kingfisher
import PromiseKit
import Alamofire

public class HNPost: HNItem {
    public var Rank: Int = 0
    public var Link: URL?

    public var ReplyHMAC: String?

    override public var description: String {
        return "HNPost: rank: \(self.Rank), type: \(self.Type.description), ID: \(self.IDString) (dead: \(self.Dead)), author: \(self.Author), score: \(self.Score), comments: \(self.TotalChildren), title: \(self.Title), link: \(self.Link), text: \(self.Text)"
    }

    var AttributedTitle: NSAttributedString {
        let badColor = UIColor(rgb: 0x828282)
        let deadLabel = NSAttributedString(string: "[dead]", attributes: [.foregroundColor: badColor])
        let flaggedLabel = NSAttributedString(string: "[flagged]", attributes: [.foregroundColor: badColor])

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: AppThemeProvider.shared.currentTheme.titleTextColor,
            .font: UIFont.mySystemFont(ofSize: 18.0)
        ]

        let titleStr = NSAttributedString(string: self.Title!, attributes: titleAttrs)

        if self.Dead, self.Flagged {
            let badTitle = NSMutableAttributedString()
            badTitle.append(deadLabel)
            badTitle.append(NSAttributedString(string: " "))
            badTitle.append(flaggedLabel)
            badTitle.append(NSAttributedString(string: " "))
            badTitle.append(titleStr)

            return badTitle
        } else if self.Dead {
            let badTitle = NSMutableAttributedString()
            badTitle.append(deadLabel)
            badTitle.append(NSAttributedString(string: " "))
            badTitle.append(titleStr)

            return badTitle
        } else if self.Flagged {
            let badTitle = NSMutableAttributedString()
            badTitle.append(flaggedLabel)
            badTitle.append(NSAttributedString(string: " "))
            badTitle.append(titleStr)

            return badTitle
        }

        return titleStr
    }

    var Site: String? {
        return self.Link?.host
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.Title!, self.Link!], applicationActivities: nil)
    }

    var LinkIsYCDomain: Bool {
        guard let urlStr = self.Link else { return false }
        return urlStr.absoluteString.contains("ycombinator.com")
    }

    var Domain: String? {
        guard let link = self.Link else { return nil }

        guard let urlComponents = URLComponents(url: link, resolvingAgainstBaseURL: true),
            var host = urlComponents.host else {
                return nil
        }

        if host.starts(with: "www.") {
            host = String(host[4...])
        }

        guard host != "news.ycombinator.com" else { return nil }

        return host
    }

    var ThumbnailCacheKey: String {
        return self.IDString
    }

    var ThumbnailFileURL: URL {
        return URL(fileURLWithPath: ImageCache.default.cachePath(forKey: self.ThumbnailCacheKey))
    }

    var ThumbnailURL: URL? {
        guard let link = self.Link else { return nil }

        // Three options for thumbnails
        // 1. https://drcs9k8uelb9s.cloudfront.net/ is the hn.algolia.com thumbnail cache
        //   three sizes are available
        //   /id.png - 100x100
        //   /id-600x315.png - 600x315
        //   /id-240x180.png - 240x180
        // 2. https://image-extractor.now.sh/?url= - weiran's service, extracts images (in order) by file extension,
        //    mime type, open graph, then scanning the HTML
        // 3. https://hackers-image-extractor.herokuapp.com/?url= - robbiet480's service, same as weiran's except with caching
        //    and order is open graph, file extension, mime type, scanning HTML.
        return URL(string: "https://hackers-image-extractor.herokuapp.com/?url=" + link.absoluteString)
    }

    var ThumbnailImageResource: ImageResource? {
        if let url = self.ThumbnailURL {
            return ImageResource(downloadURL: url, cacheKey: self.ThumbnailCacheKey)
        }

        return nil
    }

    func Thumbnail(_ needsPNG: Bool = false, handler: @escaping (UIImage?) -> Void) {
        if self.LinkIsYCDomain {
            if needsPNG, let url = Bundle.main.url(forResource: "ycombinator-logo", withExtension: "png") {
                handler(UIImage(contentsOfFile: url.path))
                return
            }

            handler(UIImage(named: "ycombinator-logo"))
            return
        }

        guard let ir = self.ThumbnailImageResource else { handler(nil); return }

        KingfisherManager.shared.retrieveImage(with: ir, options: nil, progressBlock: nil) { (image, error, _, _) in
            print("Image retrieved", self.ID)
            if let error = error {
                print("Error when getting thumbnail for post", self.ID, "with img url", ir, error)
                handler(nil)
                return
            }

            handler(image)
            return
        }
    }

    func GetReplyHMAC() -> Promise<String> {
        if let replyHMAC = self.ReplyHMAC {
            return Promise.value(replyHMAC)
        }

        return HNScraper.shared.GetItem(self.ID, dataSource: HTMLDataSource()).then { item -> Promise<String> in
            let post = item as! HNPost
            return Promise.value(post.ReplyHMAC!)
        }
    }

    func Reply(_ commentText: String) -> Promise<HNComment?> {
        return firstly { () -> Promise<String> in
            return self.GetReplyHMAC()
        }.then { (replyHMAC) -> Promise<(string: String, response: PMKAlamofireDataResponse)> in
            let parameters: Parameters = ["parent": self.ID, "goto": "item?id=" + self.IDString,
                                          "hmac": replyHMAC, "text": commentText]
            return Alamofire.request("https://news.ycombinator.com/comment", method: .post,
                                     parameters: parameters, encoding: URLEncoding.httpBody).responseString()
        }.then { resp -> Promise<HNComment?> in
            // Look for a element like this to find our newly inserted comment:
            // <td valign="top" class="votelinks">
            //    <center>
            //        <font color="#ff6600">*</font><br><img src="s.gif" height="1" width="14">
            //    </center>
            // </td>

            let document = try SwiftSoup.parse(resp.string)

            let newCommentHandle = try document.select(".votelinks [color='#ff6600']")

            let newCommentElm = newCommentHandle.parents().first(where: { (elm) -> Bool in
                return elm.hasClass("comtr")
            })

            if let newComment = newCommentElm {
                return Promise.value(HTMLHNComment(newComment))
            }

            return Promise.value(nil)
        }
    }
}
