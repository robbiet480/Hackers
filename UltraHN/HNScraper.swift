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

public class NewHNScraper {
    public static let shared: NewHNScraper = NewHNScraper()

    public static var defaultDataSource = HTMLDataSource()

    public func GetPage(_ pageName: NewHNScraper.Page, dataSource: HNDataSource = defaultDataSource) -> Promise<[NewHNItem]?> {
        return dataSource.GetPage(pageName)
    }

    public func GetItem(_ itemID: Int, dataSource: HNDataSource = defaultDataSource) -> Promise<NewHNItem?> {
        return dataSource.GetItem(itemID)
    }

    public func GetUser(_ username: String, dataSource: HNDataSource = defaultDataSource) -> Promise<NewHNUser?> {
        return dataSource.GetUser(username)
    }

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
        /// Today's front page
        case Front
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

        public static var allCases: [Page] {
            return [.Home, .Classic, .Front, .New, .Jobs, .AskHN, .ShowHN, .ShowHNNew, .Active, .Best, .Noob]
        }

        var description: String {
            switch self {
            /// Home page
            case .Home:
                return "News"
            /// Classic algorithm home page
            case .Classic:
                return "Classic"
            /// Today's front page
            case .Front:
                return "Front"
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
            case .ForDate(let storedDate):
                let date = storedDate != nil ? storedDate! : Date()

                return "Home page for " + date.formatter().string(from: date)
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
            }
        }
    }
}
