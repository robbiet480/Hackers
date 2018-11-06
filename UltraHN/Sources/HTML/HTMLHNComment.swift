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

        self.Type = .comment

        // First, we get the comment ID

        guard let commentID = Int(string: element.id()) else {
            print("No ID on comment elm!")
            return nil
        }

        self.ID = commentID

        // Next, let's determine the depth/level.

        var shouldCollapse: Bool = element.hasClass("coll")

        if let level = self.DetermineLevel(element) {
            self.Level = level

            if self.Level > 0 {
                if let parentElm = self.FindParent(element), let parentID = Int(string: parentElm.id()) {

                    self.ParentID = parentID

                    shouldCollapse = parentElm.hasClass("coll")
                }
            }
        }

        // Parent comments should be compact, Child comments should be hidden
        if shouldCollapse && self.ParentID != nil {
            self.Visibility = .Hidden
        } else if shouldCollapse {
            self.Visibility = .Compact
        }

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

        if let time = try? element.select(".age").text(), let parsed = HNScraper.shared.parseRelativeTime(time) {
            self.CreatedAt = parsed
        }

        _ = try? element.select(".commtext .reply").remove()

        var commText = try? element.select(".commtext").html()

        // Replace any truncated links
        if let hrefs = try? element.select(".commtext a") {
            for href in hrefs {
                guard let link = try? href.attr("href") else { continue }
                guard let text = try? href.text() else { continue }
                guard text.hasSuffix("...") else { continue }
                commText = commText?.replacingOccurrences(of: text, with: link)
            }
        }

        self.Text = commText

        if let fadeClasses = try? element.select(".commtext").attr("class") {
            self.FadeLevel = self.MapFadeLevel(fadeClasses)
        }

        if let comHead = try? element.select(".comhead").text() {
            self.Dead = comHead.contains("[dead]")
            self.Flagged = comHead.contains("[flagged]")
        }

        self.ExtractActions(element.ownerDocument()!)

        // print("Processed comment", self.ID)

        return
    }

    func DetermineLevel(_ element: Element) -> Int? {
        guard let indentWidth = try? element.select("img[src='s.gif']").attr("width") else {
            print("No indent width on comment elm!")
            return nil
        }

        // Level 1 = 40px, Level 2 = 80px..., so we just need to divide the indentWidth by 40 to get the level number.

        guard let indentInt = Int(string: indentWidth) else {
            print("Cant convert indent to int on comment elm!");
            return nil
        }

        return (indentInt / 40)
    }

    // This function works except for path finding. Sometimes it will add an extra ID just before hitting level 0 (0-indexed).
    /* func FindParent(_ currentLevel: Int, _ element: Element, _ checkedIDs: [Int] = []) -> (ParentID: Int, Path: [Int])? {
        guard let aboveElm = try? element.previousElementSibling(),
              let aboveUsSibling = aboveElm else { print("No previous sibling!!!"); return nil }

        guard let aboveUsLevel = self.DetermineLevel(aboveUsSibling) else { print("Divined is nil"); return nil }

        guard let aboveUsID = Int(string: aboveUsSibling.id()) else { print("Not a valid ID!!!"); return nil }

        if aboveUsLevel != 0 {
            let newIDs = aboveUsLevel < currentLevel ? checkedIDs + [aboveUsID] : checkedIDs

            print("no good", currentLevel, "-", element.id(), aboveUsLevel, "-", aboveUsID, newIDs)

            return self.FindParent(currentLevel, aboveUsSibling, newIDs)
        }

        return (aboveUsID, checkedIDs)
    }*/

    func FindParent(_ element: Element) -> Element? {
        guard let aboveElm = try? element.previousElementSibling(),
            let aboveUsSibling = aboveElm else { print("No previous sibling!!!"); return nil }

        guard let aboveUsLevel = self.DetermineLevel(aboveUsSibling) else { print("Divined is nil"); return nil }

        if aboveUsLevel != 0 {
            return self.FindParent(aboveUsSibling)
        }

        return aboveUsSibling
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
}
