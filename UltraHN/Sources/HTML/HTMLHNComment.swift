//
//  HTMLHNComment.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/30/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftSoup
import PromiseKit

public class HTMLHNComment: HNComment {

    public func ParseHTMLForComments(_ document: Document) -> [HNComment]? {
        guard let commentTree = try? document.select(".comment-tree .comtr") else { return nil }

        return commentTree.compactMap { HTMLHNComment($0) }
    }

    public convenience init?(_ element: Element) {
        self.init()

        // First, we get the comment ID

        guard let commentID = Int(string: element.id()) else { return nil }

        self.ID = commentID

        // Next, let's determine the depth/level.

        guard let indentWidth = try? element.select("img[src='s.gif']").attr("width") else { return nil }

        // Level 1 = 40px, Level 2 = 80px..., so we just need to divide the indentWidth by 40 to get the level number.

        guard let indentInt = Int(string: indentWidth) else { return nil }

        self.Level = (indentInt / 40)

        // Here's a fun hack to get the story ID:
        // The reply link looks like this: /reply?id=18342697&goto=item%3Fid%3D18341572%2318342697
        // That goto decodes to something like item?id=18341572#18342697
        // where 18341572 is the story ID and 18342697 is the ID of the comment you would be replying to.

        if let replyHref = try? element.select(".reply a").attr("href"),
            let components = URLComponents(string: replyHref),
            let goto = components.queryItemsDictionary["goto"], let storyIDStr = goto.split(separator: "#").first {

            self.StoryID = Int(string: String(storyIDStr))
        }

        if let hnUserElms = try? element.select(".hnuser"), let hnUser = hnUserElms.first() {
            self.Author = HTMLHNUser(hnUserElement: hnUser)
        }

        if let time = try? element.select(".age").text() {
            self.RelativeTime = time
        }

        self.Text = try? element.select("commtext").text()

        if let fadeClasses = try? element.select("commtext").attr("class") {
            self.FadeLevel = self.MapFadeLevel(fadeClasses)
        }

        self.ExtractActions(element.ownerDocument()!)

        return nil
    }

    public var FadeLevelClassMap: [String: Int] {
        return ["c00": 0, "c5a": 1, "c73": 2, "c82": 3, "c88": 4, "c9c": 5, "cae": 6, "cbe": 7, "cce": 8, "cdd": 9]
    }

    func MapFadeLevel(_ classes: String) -> Int {

        var fadeClass = classes

        if fadeClass.contains(Character.space), let lastPiece = fadeClass.split(separator: Character.space).last {
            fadeClass = String(lastPiece)
        }

        if let fadeLevel = self.FadeLevelClassMap[fadeClass] {
            return fadeLevel
        }

        // No class in the map found...
        return 0
    }

    func GetReplyHMAC() -> Promise<String> {
        return Alamofire.request("https://news.ycombinator.com/reply", method: .get, parameters: ["id": self.ID],
                                 encoding: URLEncoding.queryString).responseString().then { html, _ -> Promise<String> in
            let document = try SwiftSoup.parse(html)

            return Promise.value(try document.select("input[name='hmac']").val())
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
