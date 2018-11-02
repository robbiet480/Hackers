//
//  HNScraper.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftSoup
import Alamofire
import PromiseKit

public class HNScraper {
    public static let shared: HNScraper = HNScraper()

    /// Setting this to true will cause realtime updates to be sent to the NotificationCenter.
    /// See HNRealtime for more information.
    public var automaticallyMonitorItems: Bool = true

    public static var defaultDataSource = HTMLDataSource()

    public func GetPage(_ pageName: HNScraper.Page,
                        pageNumber: Int = 1, dataSource: HNDataSource = defaultDataSource) -> Promise<[HNItem]?> {
        return dataSource.GetPage(pageName, pageNumber: pageNumber).then { items -> Promise<[HNItem]?> in
            _ = HNRealtime.shared.Monitor(pageName)
            items?.forEach { _ = HNRealtime.shared.Monitor($0.ID, $0.Type) }
            return Promise.value(items)
        }
    }

    public func GetItem(_ itemID: Int, dataSource: HNDataSource = defaultDataSource) -> Promise<HNItem?> {
        return dataSource.GetItem(itemID).then { item -> Promise<HNItem?> in
            if let item = item { _ = HNRealtime.shared.Monitor(item.ID, item.Type) }
            return Promise.value(item)
        }
    }

    public func GetUser(_ username: String, dataSource: HNDataSource = defaultDataSource) -> Promise<HNUser?> {
        return dataSource.GetUser(username).then { user -> Promise<HNUser?> in
            if let user = user { _ = HNRealtime.shared.Monitor(user.Username) }
            return Promise.value(user)
        }
    }

    public func GetChildren(_ itemID: Int, dataSource: HNDataSource = defaultDataSource) -> Promise<[HNItem]?> {
        return self.GetItem(itemID, dataSource: dataSource).map({ $0?.Children as [HNItem]? })
    }

    public var ActionsCache: [Int: HNItem.Actions] = [:]

    /// Errors thrown by the scraper
    public enum HNScraperError: Error {
        /// When a method fails to parse structured data
        case parsingError
        /// A specified url is either malformed or points to a non-existing resource
        case invalidURL
        /// No internet connection
        case noInternet
        /// The user attempted an action that requires a login but they are not.
        case notLoggedIn
        /// No data could be retrieved from the specified location
        case noData
        /// Problem on server side
        case serverUnreachable
        /// When the username used to make a request doesn't exist (doesn't apply to login attempts)
        case noSuchUser
        /// When the post id used to make a request doesn't exist
        case noSuchPost
        case unknown

        /* init?(_ error: ResourceFetcher.ResourceFetchingError?) {
            if error == nil {
                return nil
            }
            if error == .noIternet {
                self = .noInternet
            } else if error == .noData {
                self = .noData
            } else if error == .invalidURL || error == .badHTTPRequest400Range {
                self = .invalidURL
            } else if error == .serverError500Range ||  error == .serverUnreachable || error == .securityIssue {
                self = .serverUnreachable
            } else if error == .parsingError {
                self = .parsingError
            } else {
                self = .unknown
            }
        } */
    }

    public enum Page: Equatable, CaseIterable {
        /// Home page
        case Home
        /// Classic algorithm home page
        case Classic
        /// Latest submissions
        case New
        /// Jobs only
        case Jobs
        /// Ask HN only (new first)
        case AskHN
        /// Show HN only (top)
        case ShowHN
        /// Show HN only (latest)
        case ShowHNNew
        /// All news with most active discussion thread first
        case Active
        /// Highest (recent) score
        case Best
        /// More recent, only by new users
        case Noob
        /// Submissions with more than the given point value
        case Over(points: Int)
        /// Homepage for a specific date
        case ForDate(date: Date?)
        /// Posts submitted by the given username
        case SubmissionsForUsername(username: String)
        /// Comments submitted by the given username
        case CommentsForUsername(username: String)
        /// Posts favorited by the given username
        case FavoritesForUsername(username: String)
        /// Posts upvoted by the given username - private, only available if user is logged in and only for themselves
        case Upvoted(username: String)
        /// Posts hidden by the given username - private, only available if user is logged in and only for themselves
        case Hidden(username: String)
        /// Posts from the provided domainName
        case Site(domainName: String)

        public static var allCases: [Page] {
            return [.Home, .Classic, .New, .Jobs, .AskHN, .ShowHN, .ShowHNNew, .Active, .Best, .Noob, .ForDate(date: Date())]
        }

        var description: String {
            switch self {
            /// Home page
            case .Home:
                return "News"
            /// Classic algorithm home page
            case .Classic:
                return "Classic"
            /// Latest submissions
            case .New:
                return "New"
            /// Jobs
            case .Jobs:
                return "Jobs"
            /// Ask HN
            case .AskHN:
                return "Ask HN"
            /// Show HN
            case .ShowHN:
                return "Show HN (Top)"
            /// Show HN
            case .ShowHNNew:
                return "Show HN (Latest)"
            /// All news with most active discussion thread first
            case .Active:
                return "Active"
            /// Highest (recent) score
            case .Best:
                return "Best"
            /// More recent, only by new users
            case .Noob:
                return "Noob"
            case .Over(let points):
                return "Submissions with over " + points.description + " points"
            /// Front page submissions for a given day ordered by time spent there.
            /// If date is nil, today is used.
            case .ForDate(let storedDate):
                let date = storedDate != nil ? storedDate! : Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"

                return "Home page for " + formatter.string(from: date)
            case .SubmissionsForUsername(let username):
                return username + "'s submitted stories"
            case .CommentsForUsername(let username):
                return username + "'s submitted comments"
            case .FavoritesForUsername(let username):
                return username + "'s favorited stories"
            case .Upvoted(let username):
                return username + "'s upvoted stories"
            case .Hidden(let username):
                return username + "'s hidden stories"
            case .Site(let domainName):
                return "Submissions from " + domainName
            }
        }
    }
}
