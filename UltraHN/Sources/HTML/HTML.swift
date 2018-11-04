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
    public init() { }

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

    public func GetItem(_ itemID: Int) -> Promise<HNItem?> {
        let url = "https://news.ycombinator.com/item?id=" + itemID.description

        return firstly {
                return self.Get(url)
            }.then { html, _ -> Promise<HNItem?> in
                let parsedHTML = try SwiftSoup.parse(html)

                let selectingClass: ParsingLinkType = (try parsedHTML.select(".fatitem .comment").first() != nil) ? .Comment : .Story

                let html = try parsedHTML.select(selectingClass.htmlSelector).first()

                let post = try HNPost(html!, rank: nil)

                let comments = HTMLHNComment().ParseHTMLForComments(parsedHTML)

                post.Children = comments

                return Promise.value(post)
        }
    }

    public func GetPage(_ pageName: HNScraper.Page, pageNumber: Int = 1) -> Promise<[HNItem]?> {
        return firstly {
                return self.Get(pageName.url(pageNumber))
            }.then { html, _ -> Promise<[HNItem]?> in
                let parsedHTML = try SwiftSoup.parse(html)

                var selectingClass = ParsingLinkType.Page

                if let fatItem = try parsedHTML.select(".fatitem").first() {
                    selectingClass = (try fatItem.select(".fatitem .comment").first() != nil) ? .Comment : .Story
                }

                let postLines = try parsedHTML.select(selectingClass.htmlSelector)

                let posts = postLines.enumerated().compactMap { item in
                    return try? HNPost(item.element, rank: item.offset + 1)
                }

                return Promise.value(posts)

        }
    }

    public func GetUser(_ username: String) -> Promise<HNUser?> {
        let pageURL = "https://news.ycombinator.com/user?id=" + username

        return self.Get(pageURL).then({ (arg0) -> Promise<HNUser?> in
            guard let parsedHTML = try? SwiftSoup.parse(arg0.string) else { return Promise.value(nil) }

            guard let user = try? HTMLHNUser(userPage: parsedHTML) else { return Promise.value(nil) }

            return Promise.value(user)
        })
    }

    public var SupportedPages: [HNScraper.Page] {
        return HNScraper.Page.allCases
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

                leaders.append(HNLeader(rank: rank, user: HNUser(username: username), karma: karma))
            }

            return Promise.value(leaders)

        })
    }

    public func GetIDsOnPage(_ pageName: HNScraper.Page) -> Promise<[Int]> {
        return self.GetPage(pageName).compactMap { $0 }.mapValues { $0.ID }
    }
}

extension HNPost {
    public convenience init(_ element: Element, rank: Int? = nil) throws {
        self.init()

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
                if linkStr == "item?id=" + self.IDString {
                    linkStr = "https://news.ycombinator.com/" + linkStr
                }

                self.Link = URL(string: linkStr)
            }

            if let scoreStr = try metadataLine?.select(".score").text(),
                let numStr = scoreStr.split(separator: .space).first, let intScore = Int(string: numStr.description) {
                self.Score = intScore
                scoreParsed = true
            }

            if let hnUserElms = try metadataLine?.select(".hnuser"), let hnUser = hnUserElms.first() {
                self.Author = HTMLHNUser(hnUserElement: hnUser)
            }

            if let time = try metadataLine?.select(".age").text(), let parsed = HNScraper.shared.parseRelativeTime(time) {
                self.CreatedAt = parsed
            }

            if let countText = try metadataLine?.select("a").last()?.text(),
                let escaped = try? Entities.unescape(countText).trimmingCharacters(in: .whitespacesAndNewlines),
                let split = escaped.split(separator: " ").first?.description, let intCount = Int(string: split) {

                self.TotalChildren = intCount
                commentsParsed = true
            }

            if !scoreParsed && !commentsParsed {
                self.Type = .job
            } else if let title = self.Title {
                if title.hasPrefix("Ask HN") {
                    self.Type = .askHN
                } else if title.hasPrefix("Show HN") {
                    self.Type = .showHN
                }
            }

            self.ReplyHMAC = try element.ownerDocument()?.select("input[name='hmac']").first()?.val()

            // Attempt to extract post text from Ask HN, jobs, etc
            if self.Link == nil, let tds = try element.ownerDocument()?.select(".fatitem tr td").array(), tds.count >= 6 {
                self.Text = try tds[6].html()
            }

            self.ExtractActions(element.ownerDocument()!)
        } catch let error as NSError {
            throw error
        }
    }
}

extension HNScraper.Page {
    fileprivate func url(_ pageNumber: Int = 1) -> URL {
        var components = URLComponents(string: "https://news.ycombinator.com/")!

        var queryItems: [URLQueryItem] = []

        queryItems.append(URLQueryItem(name: "p", value: String(pageNumber)))

        switch self {
        case .Home:
            components.path = "/news"
        case .Classic:
            components.path = "/classic"
        case .New:
            components.path = "/newest"
        case .Jobs:
            components.path = "/jobs"
        case .AskHN:
            components.path = "/ask"
        case .ShowHN:
            components.path = "/show"
        case .ShowHNNew:
            components.path = "/shownew"
        case .Active:
            components.path = "/active"
        case .Best:
            components.path = "/best"
        case .Noob:
            components.path = "/noobstories"
        case .Over(let points):
            components.path = "/over"
            queryItems.append(URLQueryItem(name: "points", value: String(points)))
        case .ForDate(let storedDate):
            let date = storedDate != nil ? storedDate! : Date()
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            components.path = "/front"
            queryItems.append(URLQueryItem(name: "day", value: dateFormatter.string(from: date)))
        case .CommentsForUsername(let username):
            components.path = "/comments"
            queryItems.append(URLQueryItem(name: "id", value: username))
        case .SubmissionsForUsername(let username):
            components.path = "/submitted"
            queryItems.append(URLQueryItem(name: "id", value: username))
        case .FavoritesForUsername(let username):
            components.path = "/favorites"
            queryItems.append(URLQueryItem(name: "id", value: username))
        case .Upvoted(let username):
            components.path = "/upvoted"
            queryItems.append(URLQueryItem(name: "id", value: username))
        case .Hidden(let username):
            components.path = "/hidden"
            queryItems.append(URLQueryItem(name: "id", value: username))
        case .Site(let domainName):
            components.path = "/from"
            queryItems.append(URLQueryItem(name: "site", value: domainName))
        }

        components.queryItems = queryItems

        return components.url!
    }
}

extension HNScraper {
    fileprivate func GetFNID() -> Promise<String> {
        return HTMLDataSource().Get("https://news.ycombinator.com/submit").then { resp -> Promise<String> in
            guard let document = try? SwiftSoup.parse(resp.string) else { return Promise.init(error: NSError()) }

            guard let fnid = try document.select("[name='fnid']").first()?.val() else { return Promise.init(error: NSError()) }

            return Promise.value(fnid)
        }
    }

    public func Submit(_ title: String, url: URL?, text: String?) -> Promise<HNPost?> {
        return firstly { () -> Promise<String> in
                return self.GetFNID()
            }.then { (fnid) -> Promise<(string: String, response: PMKAlamofireDataResponse)> in
                var parameters: Parameters = ["fnid": fnid, "fnop": "submit-page", "title": title]

                if let url = url {
                    parameters["url"] = url.absoluteString
                } else if let text = text {
                    parameters["text"] = text
                }

                return Alamofire.request("https://news.ycombinator.com/r", method: .post,
                                         parameters: parameters, encoding: URLEncoding.httpBody).responseString()
            }.then { resp -> Promise<HNPost?> in
                let document = try SwiftSoup.parse(resp.string)

                guard let item = try document.select(".athing").first() else { return Promise.value(nil) }

                return Promise.value(try HNPost(item))
        }
    }

    public func parseRelativeTime(_ rTime: String) -> Date? {
        let splitTime = rTime.split(separator: .space)
        guard let first = splitTime.first else { return nil }

        let numberStr = String(first)

        guard let number = Int(numberStr) else { return nil }

        let unit = String(splitTime[1])

        var components = DateComponents()

        switch unit {
            case "minute", "minutes":
                components.minute = -number
            case "hour", "hours":
                components.hour = -number
            case "day", "days":
                components.day = -number
            case "week", "weeks":
                components.day = -(number * 7)
            case "month", "months":
                components.month = -number
            case "year", "years":
                components.year = -number
            default:
                print("Unknown relative date unit", unit)
        }

        return Calendar.current.date(byAdding: components, to: Date())
    }
}
