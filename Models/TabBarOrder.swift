//
//  TabBarOrder.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/22/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import FontAwesome_swift

class TabBarItem: Object {
    @objc dynamic var view: View = .Home
    @objc dynamic var index: Int = 0
    @objc dynamic var associatedValue: String = ""

    @objc public enum View: Int, CaseIterable {
        /// Home page
        case Home
        /// Classic algorithm home page
        case Classic
        /// Latest submissions
        case New
        /// Jobs
        case Jobs
        /// Ask HN
        case AskHN
        /// Show HN
        case ShowHN
        /// All news with most active discussion thread first
        case Active
        /// Highest (recent) score
        case Best
        /// Most recent stories submitted by new users
        case Noob
        /// Submissions with more than the given point value
        case Over
        /// Homepage for a specific date
        case ForDate
        /// Posts submitted by the given username
        case SubmissionsForUsername
        /// Comments submitted by the given username
        case CommentsForUsername
        /// Posts favorited by the given username
        case FavoritesForUsername
        /// Posts upvoted by the given username - private, only available if user is logged in and only for themselves
        case Upvoted
        /// Posts hidden by the given username - private, only available if user is logged in and only for themselves
        case Hidden
        /// Posts from the provided domainName
        case Site
        /// Users profile
        case Profile

        var description: String {
            switch self {
            /// Home page
            case .Home:
                return "Home"
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
                return "Show HN"
            /// All news with most active discussion thread first
            case .Active:
                return "Active"
            /// Highest (recent) score
            case .Best:
                return "Best"
            /// More recent, only by new users
            case .Noob:
                return "Noob"
            case .Over:
                return "Most Points"
            case .ForDate:
                return "Time Machine"
            case .SubmissionsForUsername:
                return "My Stories"
            case .CommentsForUsername:
                return "My Comments"
            case .FavoritesForUsername:
                return "My Favorites"
            case .Upvoted:
                return "My Upvoted Stories"
            case .Hidden:
                return "My Hidden Stories"
            case .Site:
                return "Site posts"
            case .Profile:
                return "Profile"
            }
        }

        init?(_ scraperPage: HNScraper.Page) {
            switch scraperPage {
            /// Home page
            case .Home:
                self = .Home
            /// Classic algorithm home page
            case .Classic:
                self = .Classic
            /// Latest submissions
            case .New:
                self = .New
            /// Jobs
            case .Jobs:
                self = .Jobs
            /// Ask HN
            case .AskHN:
                self = .AskHN
            /// Show HN
            case .ShowHN:
                self = .ShowHN
            /// All news with most active discussion thread first
            case .Active:
                self = .Active
            /// Highest (recent) score
            case .Best:
                self = .Best
            /// More recent, only by new users
            case .Noob:
                self = .Noob
            case .Over:
                self = .Over
            case .ForDate:
                self = .ForDate
            case .SubmissionsForUsername:
                self = .SubmissionsForUsername
            case .CommentsForUsername:
                self = .CommentsForUsername
            case .FavoritesForUsername:
                self = .FavoritesForUsername
            case .Upvoted:
                self = .Upvoted
            case .Hidden:
                self = .Hidden
            case .Site:
                self = .Site
            default:
                return nil
            }
        }

        func scraperPage(_ associatedValue: String) -> HNScraper.Page {
            switch self {
            /// Home page
            case .Home:
                return .Home
            /// Classic algorithm home page
            case .Classic:
                return .Classic
            /// Latest submissions
            case .New:
                return .New
            /// Jobs
            case .Jobs:
                return .Jobs
            /// Ask HN
            case .AskHN:
                return .AskHN
            /// Show HN
            case .ShowHN:
                return .ShowHN
            /// All news with most active discussion thread first
            case .Active:
                return .Active
            /// Highest (recent) score
            case .Best:
                return .Best
            /// More recent, only by new users
            case .Noob:
                return .Noob
            case .Over:
                return .Over(points: Int(string: associatedValue)!)
            case .ForDate:
                if associatedValue != "" {
                    return .ForDate(date: Date(timeIntervalSince1970: TimeInterval(string: associatedValue)!))
                }
                return .ForDate(date: nil)
            case .SubmissionsForUsername:
                return .SubmissionsForUsername(username: associatedValue)
            case .CommentsForUsername:
                return .CommentsForUsername(username: associatedValue)
            case .FavoritesForUsername:
                return .FavoritesForUsername(username: associatedValue)
            case .Upvoted:
                return .Upvoted(username: associatedValue)
            case .Hidden:
                return .Hidden(username: associatedValue)
            case .Site:
                return .Site(domainName: associatedValue)
            case .Profile: // Not actually home...
                return .Home
            }
        }

        var iconName: String? {
            switch self {
            case .Home:
                return "TopIcon"
            case .AskHN:
                return "AskIcon"
            case .Jobs:
                return "JobsIcon"
            case .New:
                return "NewIcon"
            default:
                return nil
            }
        }

        var tabBarIcon: UIImage {
            var iconName: FontAwesome = .questionCircle

            switch self {
            case .Home:
                iconName = .home
            case .New:
                iconName = .clock
            case .Jobs:
                iconName = .briefcase
            case .AskHN:
                iconName = .question
            case .ShowHN:
                iconName = .eye
            case .Active:
                iconName = .fire
            case .Best:
                iconName = .star
            case .Noob:
                iconName = .child
            case .Over:
                iconName = .thermometer
            case .ForDate:
                iconName = .history
            case .SubmissionsForUsername:
                iconName = .userPlus
            case .CommentsForUsername:
                iconName = .comments
            case .FavoritesForUsername:
                iconName = .grinStars
            case .Upvoted:
                iconName = .arrowUp
            case .Hidden:
                iconName = .eyeSlash
            case .Site:
                iconName = .globe
            case .Classic:
                iconName = .codeBranch
            case .Profile:
                iconName = .userCircle
            }

            return UIImage.fontAwesomeIcon(name: iconName, style: .solid,
                                           textColor: AppThemeProvider.shared.currentTheme.barForegroundColor,
                                           size: CGSize(width: 30, height: 30))
        }

        func barItem(_ tag: Int) -> UITabBarItem {
            return UITabBarItem(title: self.description, image: self.tabBarIcon, tag: tag)
        }
    }


    convenience init(_ index: Int, _ view: View) {
        self.init()

        self.index = index
        self.view = view
    }

    convenience init(_ index: Int, _ scraperPage: HNScraper.Page) {
        self.init()

        self.index = index
        switch scraperPage {
            /// Home page
            case .Home:
                self.view = .Home
            /// Classic algorithm home page
            case .Classic:
                self.view = .Classic
            /// Latest submissions
            case .New:
                self.view = .New
            /// Jobs
            case .Jobs:
                self.view = .Jobs
            /// Ask HN
            case .AskHN:
                self.view = .AskHN
            /// Show HN
            case .ShowHN, .ShowHNNew:
                self.view = .ShowHN
            /// All news with most active discussion thread first
            case .Active:
                self.view = .Active
            /// Highest (recent) score
            case .Best:
                self.view = .Best
            /// More recent, only by new users
            case .Noob:
                self.view = .Noob
            case .Over(let points):
                self.view = .Over
                self.associatedValue = String(points)
            case .ForDate(let date):
                self.view = .ForDate
                if let date = date {
                    self.associatedValue = String(date.timeIntervalSince1970)
                }
            case .SubmissionsForUsername(let username):
                self.view = .SubmissionsForUsername
                self.associatedValue = username
            case .CommentsForUsername(let username):
                self.view = .CommentsForUsername
                self.associatedValue = username
            case .FavoritesForUsername(let username):
                self.view = .FavoritesForUsername
                self.associatedValue = username
            case .Upvoted(let username):
                self.view = .Upvoted
            self.associatedValue = username
            case .Hidden(let username):
                self.view = .Hidden
                self.associatedValue = username
            case .Site(let domainName):
                self.view = .Site
                self.associatedValue = domainName
        }
    }
}
