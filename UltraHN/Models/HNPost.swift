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
import OpenGraph
import PromiseKit
import Alamofire

public class HNPost: HNItem {
    public var Rank: Int = 0
    public var Link: URL?

    public var ReplyHMAC: String?

    var OpenGraph: [OpenGraphMetadata.RawValue: String] = [:]

    override public var description: String {
        return "HNPost: rank: \(self.Rank), type: \(self.Type.description), ID: \(self.IDString) (dead: \(self.Dead)), author: \(self.Author), score: \(self.Score), comments: \(self.TotalChildren), title: \(self.Title), link: \(self.Link), text: \(self.Text)"
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

    var ThumbnailCacheKey: String {
        return self.IDString
    }

    var ThumbnailFileURL: URL {
        return URL(fileURLWithPath: ImageCache.default.cachePath(forKey: self.ThumbnailCacheKey))
    }

    var ThumbnailURL: URL? {
        guard let link = self.Link else { return nil }

        // https://drcs9k8uelb9s.cloudfront.net/ is the hn.algolia.com thumbnail cache
        // three sizes are available
        // /id.png - 100x100
        // /id-600x315.png - 600x315
        // /id-240x180.png - 240x180
        // Previous to this discovery, we used https://image-extractor.now.sh/?url=
        guard let fallbackURL = URL(string: "https://drcs9k8uelb9s.cloudfront.net/" + self.IDString + "-600x315.png") else { return nil }

        var ogImageURLTest: String? = nil

        let keysToCheck: [OpenGraphMetadata] = [.image, .imageUrl, .imageSecure_url]

        for ogKey in keysToCheck {
            if let ogURL = self.OpenGraph[ogKey] {
                ogImageURLTest = ogURL
                break
            }
        }

        guard let ogImageURLStr = ogImageURLTest else { return fallbackURL }

        if !ogImageURLStr.hasPrefix("http") {
            // og:image is something like /logo.png so we need to prefix it with the base URL for a valid URL.
            return URL(string: ogImageURLStr, relativeTo: link)
        }

        return URL(string: ogImageURLStr)
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

        if let ir = self.ThumbnailImageResource {
            KingfisherManager.shared.retrieveImage(with: ir, options: nil, progressBlock: nil) { (image, error, cacheType, kfURL) in
                if let error = error {
                    print("Error when getting thumbnail for post", self.ID, "with img url", kfURL, error.debugDescription)
                    handler(nil)
                    return
                }

                handler(image)
                return
            }
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
