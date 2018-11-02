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
import SwiftDate
import FontAwesome_swift

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
    public var Children: [HNComment]?
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

    var RelativeDate: String {
        if let createdAt = self.CreatedAt {
            return createdAt.toRelative(style: RelativeFormatter.twitterStyle())
        }

        return self.RelativeTime
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
            let isInitialAction = queryItems["un"] == nil

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

        func tableAction(item: HNItem, trailing: Bool = false) -> UIContextualAction? {
            switch self {
            case .Flag, .Vouch, .Unflag, .Unvouch:
                return nil
            case .Favorite, .Hide:
                if trailing { return nil }
            case .Unfavorite, .Unhide, .Unvote:
                if !trailing { return nil }
            case .Vote(_, _, let direction):
                if trailing && direction == .Up { return nil }
                if !trailing && direction == .Down { return nil }
            }

            var title = ""
            var color: UIColor = .clear
            var faIcon: FontAwesome = .arrowUp
            var iconColor: UIColor = .white

            switch self {
            case .Favorite:
                title = "Favorite"
                color = .green
                faIcon = .star
            case .Flag:
                title = "flag"
                color = .red
                faIcon = .flag
            case .Unvote:
                title = "Unvote"
                color = .orange
                faIcon = .times
            case .Hide:
                title = "Hide"
                color = .yellow
                faIcon = .eyeSlash
            case .Unfavorite:
                title = "Unfavorite"
                color = .red
                faIcon = .trashAlt
            case .Unflag:
                title = "Unflag"
                color = .green
                faIcon = .flag
                iconColor = .red
            case .Unhide:
                title = "Unhide"
                color = .green
                faIcon = .eye
            case .Unvouch:
                title = "Unvouch"
                color = .red
                faIcon = .thumbsDown
            case .Vouch:
                title = "Vouch"
                color = .red
                faIcon = .thumbsUp
            case .Vote(_, _, let direction):
                switch direction {
                case .Up:
                    title = "Upvote"
                    color = .orange
                    faIcon = .arrowUp
                case .Down:
                    title = "Downvote"
                    color = .blue
                    faIcon = .arrowDown
                }
            }

            let tableAction = UIContextualAction(style: .normal, title: title, handler: { (_, _, complete) in
                _ = item.FireAction(self)
                
                complete(false)
            })

            tableAction.backgroundColor = color
            tableAction.image = UIImage.fontAwesomeIcon(name: faIcon, style: .solid, textColor: iconColor,
                                                        size: CGSize(width: 36, height: 36))

            return tableAction
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
                    // If we can hide, we can fave
                    self.Favorite = HNItem.ActionType.Favorite(action.itemID, action.authToken)
                case .Unhide:
                    self.Unhide = action
                    self.Unfavorite = HNItem.ActionType.Unfavorite(action.itemID, action.authToken)
                case .Unflag:
                    self.Unflag = action
                }
            }
        }

        var AllActions: [HNItem.ActionType] {
            return [self.Upvote, self.Downvote, self.Unvote, self.Vouch, self.Unvouch, self.Flag, self.Unflag,
                    self.Hide, self.Unhide, self.Favorite, self.Unfavorite].compactMap { $0 }
        }

        func swipeActionsConfiguration(item: HNItem, trailing: Bool = false) -> UISwipeActionsConfiguration {
            var allTableActions: [UIContextualAction?] = []

            for action in self.AllActions {
                allTableActions.append(action.tableAction(item: item, trailing: trailing))
            }

            print("Returning actions", allTableActions)

            return UISwipeActionsConfiguration(actions: allTableActions.compactMap { $0 })
        }
    }

    func FireAction(_ action: HNItem.ActionType) -> Promise<Void> {
        // FIXME: Should probably add validation of some kind to ensure an action succeeded
        return Alamofire.request(action.url).responseString().done { (resp) in
            let html = try SwiftSoup.parse(resp.string)

            HNScraper.shared.ActionsCache[self.ID] = nil

            // Okay, so we didn't get a bad server response, so lets re-extract actions so that we have latest auth keys
            // as well as ensuring that the action we just ran is no longer runnable.
            self.ExtractActions(html)
        }
    }

    /// ExtractActions will attempt to find available actions (vote, flag, hide, etc) in the provided SwiftSoup Document.
    public func ExtractActions(_ document: Document) {
        // href looks like
        // vote?id=<ID>&how=<DIR>&auth=<AUTH KEY>&goto=<REDIRECT>

        if HNScraper.shared.ActionsCache[self.ID] != nil { /*print("Item already in cache!", self.ID, HNScraper.shared.ActionsCache[self.ID]);*/ return }

        // Action links are any links in the item details that have &auth=
        guard let linkElements = try? document.select("a[href*='&auth=']") else { return }

        // Only return active links
        let activeHrefOnly = linkElements.filter { $0.hasClass("nosee") == false }

        let allHrefs = activeHrefOnly.compactMap { try? $0.attr("href") }

        let itemHrefs = allHrefs.filter { $0.contains("id=" + self.IDString) }

        self.Actions = HNItem.Actions(itemHrefs.compactMap { HNItem.ActionType($0) })

        HNScraper.shared.ActionsCache[self.ID] = self.Actions

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
            HNScraper.shared.ActionsCache[id] = actions
        }

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

    // Putting this here for later...
    // URL is https://news.ycombinator.com/delete-confirm?id=<ID>&goto=<URL Encoded return>
    // Extract the HMAC much like replying
    // POST same params as replying to /xdelete
    /* func Delete() -> Promise<Void> {


    }*/

    // Putting this here for later...
    // URL is https://news.ycombinator.com/edit?id=<ID>
    // Extract the HMAC much like replying
    // POST same params as replying to /xedit
    /* func Edit(_ newText: String) -> Promise<Void> {


     }*/
}
