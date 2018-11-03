//
//  HNComment.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftSoup

public class HNComment: HNItem {
    override public var description: String {
        return "HNComment: author: \(self.Author!)"
    }

    // FadeLevel equates to number of downvotes received after the comment already had 0 points.
    // The higher the level the more downvotes you have.
    // There are 10 levels in all
    var FadeLevel: Int = 0

    // FadeColor is the text color you should use when displaying the comment to match Hacker News stylings.
    public var FadeColor: UIColor {
        switch self.FadeLevel {
            case 0:
                return UIColor(rgb: 0x000000)
            case 1:
                return UIColor(rgb: 0x5A5A5A)
            case 2:
                return UIColor(rgb: 0x737373)
            case 3:
                return UIColor(rgb: 0x828282)
            case 4:
                return UIColor(rgb: 0x888888)
            case 5:
                return UIColor(rgb: 0x9C9C9C)
            case 6:
                return UIColor(rgb: 0xAEAEAE)
            case 7:
                return UIColor(rgb: 0xBEBEBE)
            case 8:
                return UIColor(rgb: 0xCECECE)
            default: // We use level 9 as the default since that color is basically unreadable on light backgrounds.
                return UIColor(rgb: 0xDDDDDD)
        }
    }

    // FadeAlpha is the text color you should use when displaying the comment to match Hacker News stylings.
    public var FadeAlpha: CGFloat {
        switch self.FadeLevel {
        case 0:
            return 1.0
        case 1:
            return 0.888888889
        case 2:
            return 0.777777778
        case 3:
            return 0.666666667
        case 4:
            return 0.555555556
        case 5:
            return 0.444444445
        case 6:
            return 0.333333334
        case 7:
            return 0.222222223
        case 8:
            return 0.111111112
        default: // We use level 9 as the default since that color is basically unreadable on light backgrounds.
            return 0.05
        }
    }

    func Hide() -> Promise<Void> {
        return Alamofire.request("https://news.ycombinator.com/collapse?id=" + self.IDString).responseData().asVoid()
    }

    func Show() -> Promise<Void> {
        return Alamofire.request("https://news.ycombinator.com/collapse?id=" + self.IDString + "&un=true").responseData().asVoid()
    }

    func GetReplyHMAC() -> Promise<String> {
        return Alamofire.request("https://news.ycombinator.com/reply", method: .get, parameters: ["id": self.ID],
                                 encoding: URLEncoding.queryString).responseString().then { html, _ -> Promise<String> in
                                    let document = try SwiftSoup.parse(html)

                                    guard let hmacValue = try document.select("input[name='hmac']").first()?.val() else {
                                        return Promise.init(error: NSError())
                                    }

                                    return Promise.value(hmacValue)
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
