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
            default:
                return nil
            }
        }

        var scraperPage: HNScraper.Page {
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
            default:
                print("No icon set for", self.description)
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
}
