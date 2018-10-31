//
//  HNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftSoup
import RealmSwift

public class HNItem: NSObject, Codable {
    public var Author: HNUser?
    public var Dead: Bool?
    public var Flagged: Bool?
    public var Title: String?
    public var Text: String?
    public var Score: Int?
    public var ID: Int = 0
    public var RelativeTime: String = ""
    public var CreatedAt: Date?
    public var `Type`: HNItemType = .story

    public var ParentID: Int?
    public var StoryID: Int?
    public var Children: [HNItem]?
    public var ChildrenIDs: [Int]?
    public var TotalChildren: Int = 0
    public var Level: Int = 0

    public var Actions: Actions?
    public var AllActions: [Int: Actions] = [:]

    public var Visibility: ItemVisibilityType = .Visible

    public enum ItemVisibilityType: Int, Codable {
        case Visible = 3
        case Compact = 2
        case Hidden = 1
    }

    /// Whether the user upvoted. If NO, they downvoted
    public var Upvoted: Bool?

    /// The time at which the user took a vote action
    public var VotedAt: Date?

    /// The date when this item was imported to the Realm.
    public var ImportedAt: Date = Date()

    /// The date when this item was marked as read.
    public var ReadAt: Date?

    public override init() { super.init() }

    private enum CodingKeys: String, CodingKey {
        case Author
        case Title
        case Text
        case Score
        case ID
        case CreatedAt
        case `Type`
        case Children
    }

    public enum HNItemType: String, CaseIterable, Codable {
        case story
        case askHN
        case job
        case comment
        case showHN
        case poll
        case pollOption

        init(_ str: String) {
            switch str.lowercased() {
            case "story":
                self = .story
            case "ask":
                self = .askHN
            case "poll":
                self = .poll
            case "job":
                self = .job
            case "comment":
                self = .comment
            case "polloption", "pollopt":
                self = .pollOption
            default:
                self = .story
            }
        }

        var description: String {
            switch self {
            case .story:
                return "Story"
            case .askHN:
                return "Ask HN"
            case .job:
                return "Job"
            case .comment:
                return "Comment"
            case .showHN:
                return "Show HN"
            case .poll:
                return "Poll"
            case .pollOption:
                return "Poll option"
            }
        }
    }

    var IDString: String {
        return String(self.ID)
    }

    public func collectChildren(_ level: Int = 0) -> [HNItem] {
        var childArray: [HNItem] = [self]

        if let children = self.Children {
            for child in children {
                child.Level = level
                childArray = childArray + child.collectChildren(level + 1)
            }
        }

        self.TotalChildren = self.TotalChildren + childArray.count - 1

        return childArray
    }

    public enum ActionType {
        case Vote(_ itemID: Int, _ authToken: String, _ direction: VoteDirection)
        case Unvote(_ itemID: Int, _ authToken: String)
        case Flag(_ itemID: Int, _ authToken: String)
        case Hide(_ itemID: Int, _ authToken: String)
        case Unflag(_ itemID: Int, _ authToken: String)
        case Unhide(_ itemID: Int, _ authToken: String)
        case Vouch(_ itemID: Int, _ authToken: String)
        case Unvouch(_ itemID: Int, _ authToken: String)
        case Favorite(_ itemID: Int, _ authToken: String)
        case Unfavorite(_ itemID: Int, _ authToken: String)

        public enum VoteDirection: String, CaseIterable {
            case Up = "up"
            case Down = "down"
        }

        init?(_ href: String) {
            guard let components = URLComponents(string: href) else { return nil }

            let queryItems = components.queryItemsDictionary

            guard let itemIDStr = queryItems["id"], let itemID = Int(string: itemIDStr) else { return nil }

            guard let authToken = queryItems["auth"] else { return nil }

            // A boolean to determine if a action was already run by checking to see if the href has a un=t value
            let isInitialAction = queryItems["un"] != nil

            switch components.path {
            case "flag":
                self = isInitialAction ? .Flag(itemID, authToken) : .Unflag(itemID, authToken)
            case "hide":
                self = isInitialAction ? .Hide(itemID, authToken) : .Unhide(itemID, authToken)
            case "fave":
                self = isInitialAction ? .Favorite(itemID, authToken) : .Unfavorite(itemID, authToken)
            case "vouch":
                self = isInitialAction ? .Vouch(itemID, authToken) : .Unvouch(itemID, authToken)
            case "vote":
                guard let how = queryItems["how"] else {
                    print("Found a vote action link without a how!", href)
                    return nil
                }

                if how == "un" {
                    self = .Unvote(itemID, authToken)
                    break
                }

                guard let dir = HNItem.ActionType.VoteDirection(rawValue: how) else {
                    print("Unknown vote direction", how)
                    return nil
                }

                self = .Vote(itemID, authToken, dir)
            default:
                print("Unknown kind of action link found", href)
                return nil
            }
        }

        var path: String {
            switch self {
                case .Vote, .Unvote: return "/vote"
                case .Flag, .Unflag: return "/flag"
                case .Hide, .Unhide: return "/hide"
                case .Vouch, .Unvouch: return "/vouch"
                case .Favorite, .Unfavorite: return "/fave"
            }
        }

        var url: URL {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "id", value: String(self.itemID)),
                URLQueryItem(name: "auth", value: self.authToken),
                URLQueryItem(name: "goto", value: "item?id=" + String(self.itemID)),
            ]

            switch self {
                case .Unflag, .Unhide, .Unfavorite, .Unvouch:
                    queryItems.append(URLQueryItem(name: "un", value: "t"))
                case .Unvote:
                    queryItems.append(URLQueryItem(name: "how", value: "un"))
                case .Vote(_, _, let direction):
                    queryItems.append(URLQueryItem(name: "how", value: direction.rawValue))
                default: break
            }

            var components = URLComponents(string: "https://news.ycombinator.com")!

            components.path = self.path

            components.queryItems = queryItems

            return components.url!
        }

        var itemID: Int {
            switch self {
            case .Favorite(let itemID, _), .Flag(let itemID, _), .Hide(let itemID, _), .Vote(let itemID, _, _),
                 .Unvote(let itemID, _), .Vouch(let itemID, _), .Unvouch(let itemID, _), .Unflag(let itemID, _),
                 .Unhide(let itemID, _), .Unfavorite(let itemID, _):
                return itemID
            }
        }

        var authToken: String {
            switch self {
            case .Favorite(_, let authToken), .Flag(_, let authToken), .Hide(_, let authToken),
                 .Vote(_, let authToken, _), .Unvote(_, let authToken), .Vouch(_, let authToken),
                 .Unvouch(_, let authToken), .Unflag(_, let authToken), .Unhide(_, let authToken),
                 .Unfavorite(_, let authToken):
                return authToken
            }
        }
    }

    public struct Actions {
        var Upvote: HNItem.ActionType?
        var Downvote: HNItem.ActionType?
        var Unvote: HNItem.ActionType?

        var Vouch: HNItem.ActionType?
        var Unvouch: HNItem.ActionType?

        var Flag: HNItem.ActionType?
        var Unflag: HNItem.ActionType?

        var Hide: HNItem.ActionType?
        var Unhide: HNItem.ActionType?

        var Favorite: HNItem.ActionType?
        var Unfavorite: HNItem.ActionType?

        init(_ actions: [HNItem.ActionType]) {
            for action in actions {
                switch action {
                case .Vote(_, _, let direction):
                    switch direction {
                    case .Up:
                        self.Upvote = action
                    case .Down:
                        self.Downvote = action
                    }
                case .Unvote:
                    self.Unvote = action
                case .Favorite:
                    self.Favorite = action
                case .Unfavorite:
                    self.Unfavorite = action
                case .Vouch:
                    self.Vouch = action
                case .Unvouch:
                    self.Unvouch = action
                case .Flag:
                    self.Flag = action
                case .Hide:
                    self.Hide = action
                case .Unhide:
                    self.Unhide = action
                case .Unflag:
                    self.Unflag = action
                }
            }
        }
    }

    func FireAction(_ action: HNItem.ActionType) -> Promise<Void> {
        // FIXME: Should probably add validation of some kind to ensure an action succeeded
        return Alamofire.request(action.url).responseString().done { (resp) in
            let html = try SwiftSoup.parse(resp.string)

            // Okay, so we didn't get a bad server response, so lets re-extract actions so that we have latest auth keys
            // as well as ensuring that the action we just run is no longer runnable.
            self.ExtractActions(html)
        }
    }

    /// ExtractActions will attempt to find available actions (vote, flag, hide, etc) in the provided SwiftSoup Document.
    public func ExtractActions(_ document: Document) {
        // href looks like
        // vote?id=<ID>&how=<DIR>&auth=<AUTH KEY>&goto=<REDIRECT>

        // Action links are any links in the item details that have &auth=
        guard let linkElements = try? document.select("a[href*='&auth=']") else { return }

        let allHrefs = linkElements.compactMap { try? $0.attr("href") }

        let itemHrefs = allHrefs.filter { $0.contains("id=" + self.IDString) }

        self.Actions = HNItem.Actions(itemHrefs.compactMap { HNItem.ActionType($0) })

        self.AllActions = self.makeChildActionsMap(allHrefs.filter { !$0.contains("id=" + self.IDString) })

        return
    }

    private func makeChildActionsMap(_ allHrefs: [String]) -> [Int: HNItem.Actions] {
        var actionsMap = [Int: HNItem.Actions]()

        var groupedHrefs: [Int: [String]] = [:]

        for href in allHrefs {
            guard let components = URLComponents(string: href) else { continue }

            guard let id = components.queryItemsDictionary["id"] else { continue }

            guard let idInt = Int(string: id) else { continue }

            if groupedHrefs[idInt] == nil { groupedHrefs[idInt] = [String]() }

            groupedHrefs[idInt]!.append(href)
        }

        for (id, groupHrefs) in groupedHrefs {
            let actions = HNItem.Actions(groupHrefs.compactMap { HNItem.ActionType($0) })
            actionsMap[id] = actions
        }

        print("Returning", actionsMap)

        return actionsMap
    }

    var ItemPageTitle: String {
        return self.Title! + " | Hacker News"
    }

    var ItemURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.IDString)!
    }

    var CommentsActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.ItemPageTitle,
                                                        self.ItemURL], applicationActivities: nil)
    }

    public static func ==(lhs: HNItem, rhs: HNItem) -> Bool {
        return lhs.ID == rhs.ID
    }
}
