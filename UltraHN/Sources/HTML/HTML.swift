//
//  HTML.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import SwiftSoup

public class HTMLDataSource: HNDataSource {
    public enum ParsingLinkType: CaseIterable {
        case Page
        case Story
        case Comment
        case User

        var htmlSelector: String {
            switch self {
            case .Page:
                return ".athing"
            case .Story, .Comment:
                return ".fatitem .athing"
            case .User:
                return "tbody"
            }
        }
    }

    public func Get(_ url: URLConvertible, parameters: Parameters? = nil) -> Promise<(string: String, response: PMKAlamofireDataResponse)> {
        return Alamofire.request(url, method: .get, parameters: parameters).responseString()
    }

    public func Post(url: URLConvertible, parameters: Parameters? = nil) -> Promise<(string: String, response: PMKAlamofireDataResponse)> {
        return Alamofire.request(url, method: .post, parameters: parameters).responseString()
    }

    public func GetItem(_ itemID: Int) -> Promise<NewHNItem?> {
        let url = "https://news.ycombinator.com/item?id=" + itemID.description

        return firstly {
                return self.Get(url)
            }.then { html, _ -> Promise<NewHNItem?> in
                let parsedHTML = try SwiftSoup.parse(html)

                let selectingClass: ParsingLinkType = (try parsedHTML.select(".fatitem .comment").first() != nil) ? .Comment : .Story

                let html = try parsedHTML.select(selectingClass.htmlSelector).first()

                return Promise.value(try NewHNPost(html!, rank: nil))
        }
    }

    public func GetPage(_ pageName: NewHNScraper.Page) -> Promise<[NewHNItem]?> {
        return firstly {
                return self.Get(pageName.url)
            }.then { html, _ -> Promise<[NewHNItem]?> in
                let parsedHTML = try SwiftSoup.parse(html)

                var selectingClass = ParsingLinkType.Page

                if let fatItem = try parsedHTML.select(".fatitem").first() {
                    selectingClass = (try fatItem.select(".fatitem .comment").first() != nil) ? .Comment : .Story
                }

                let postLines = try parsedHTML.select(selectingClass.htmlSelector)

                let posts = postLines.enumerated().compactMap { item in
                    return try? NewHNPost(item.element, rank: item.offset + 1)
                }

                // return Promise.value((posts: posts, user: try NewHNUser(documentWithHeader: parsedHTML)))
                return Promise.value(posts)

        }
    }

    public func GetUser(_ username: String) -> Promise<NewHNUser?> {
        let pageURL = "https://news.ycombinator.com/user?id=" + username

        return self.Get(pageURL).then({ (arg0) -> Promise<NewHNUser?> in
            guard let parsedHTML = try? SwiftSoup.parse(arg0.string) else { return Promise.value(nil) }

            guard let user = try? HTMLHNUser(userPage: parsedHTML) else { return Promise.value(nil) }

            return Promise.value(user)
        })
    }

    public var SupportedPages: [NewHNScraper.Page] {
        return NewHNScraper.Page.allCases
    }

    public func GetLeaders() -> Promise<[HNLeader]> {
        let pageURL = "https://news.ycombinator.com/leaders"

        return self.Get(pageURL).then({ (arg0) -> Promise<[HNLeader]> in
            var leaders: [HNLeader] = []

            let parsedHTML = try SwiftSoup.parse(arg0.string)
            let rows = try parsedHTML.select("tr.athing")
            for row in rows {
                let tds = try row.select("td").array()

                var rank: Int = 0

                var rankStr = try? tds[0].text()
                rankStr?.removeLast()

                if let rankStr = rankStr, let rankInt = Int(string: rankStr) {
                    rank = rankInt
                }
                let username = try tds[1].text()

                var karma: Int?
                if let karmaStr = try? tds[2].text(), let karmaInt = Int(string: karmaStr) {
                    karma = karmaInt
                }

                leaders.append(HNLeader(rank: rank, username: username, karma: karma))
            }

            return Promise.value(leaders)

        })
    }

    public func GetIDsOnPage(_ pageName: NewHNScraper.Page) -> Promise<[Int]> {
        return self.GetPage(pageName).compactMap { $0 }.mapValues { $0.ID }
    }
}

extension NewHNPost {
    public convenience init(_ element: Element, rank: Int? = nil) throws {
        try self.init(element)

        do {
            var commentsParsed = false
            var scoreParsed = false

            let idStr = element.id()

            let metadataLine = try element.nextElementSibling()
            let link = try element.select(".storylink")

            self.ID = Int(string: idStr)!

            self.Dead = try element.select(".title").text().contains("[dead]")
            self.Flagged = try element.select(".title").text().contains("[flagged]")

            if let rankStr = try? element.select(".rank").text().replacingOccurrences(of: ".", with: ""),
                let rankInt = Int(string: rankStr) {
                self.Rank = rankInt
            } else if let rankInt = rank {
                self.Rank = rankInt
            }

            self.Title = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)

            if var linkStr: String = try? link.attr("href") {
                if linkStr == "item?id=" + String(self.ID) {
                    linkStr = "https://news.ycombinator.com/" + linkStr
                }

                self.Link = URL(string: linkStr)
            }

            self.Site = try element.select(".sitestr").text()

            if let scoreStr = try metadataLine?.select(".score").text(), let numStr = scoreStr.split(separator: .space).first, let intScore = Int(string: numStr.description) {
                self.Score = intScore
                scoreParsed = true
            }

            self.Author = try metadataLine?.select(".hnuser").text()

            self.AuthorIsNew = try metadataLine?.select(".hnuser font").first() != nil

            if let time = try metadataLine?.select(".age").text() {
                self.RelativeTime = time
            }

            if let countText = try metadataLine?.select("a").last()?.text(),
                let escaped = try? Entities.unescape(countText).trimmingCharacters(in: .whitespacesAndNewlines),
                let split = escaped.split(separator: " ").first?.description, let intCount = Int(string: split) {

                self.CommentCount = intCount
                commentsParsed = true
            }

            if !scoreParsed && !commentsParsed {
                self.Type = .jobs
            } else if !scoreParsed {
                self.Type = .askHN
            }
        } catch let error as NSError {
            throw error
        }
    }
}

extension NewHNScraper.Page {
    var url: URL {
        var urlStr = "https://news.ycombinator.com/"
        switch self {
        case .Home:
            urlStr += "news"
        case .Classic:
            urlStr += "classic"
        case .Front:
            urlStr += "front"
        case .New:
            urlStr += "newest"
        case .Jobs:
            urlStr += "jobs"
        case .AskHN:
            urlStr += "ask"
        case .ShowHN:
            urlStr += "show"
        case .ShowHNNew:
            urlStr += "shownew"
        case .Active:
            urlStr += "active"
        case .Best:
            urlStr += "best"
        case .Noob:
            urlStr += "noobstories"
        case .Over(let points):
            urlStr += "over?points=" + points.description
        case .ForDate(let storedDate):
            let date = storedDate != nil ? storedDate! : Date()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            urlStr += "front?day=" + dateFormatter.string(from: date)
        case .CommentsForUsername(let username):
            urlStr += "comments?id=" + username
        case .SubmissionsForUsername(let username):
            urlStr += "submitted?id=" + username
        case .FavoritesForUsername(let username):
            urlStr += "favorites?id=" + username
        case .Upvoted(let username):
            urlStr += "upvoted?id=" + username
        case .Hidden(let username):
            urlStr += "hidden?id=" + username
        }

        return URL(string: urlStr)!
    }
}
