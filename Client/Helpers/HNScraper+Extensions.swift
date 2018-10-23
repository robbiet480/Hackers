//
//  HNScraper+Extensions.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/22/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import HNScraper
import FontAwesome_swift

extension HNScraper.PostListPageName {
    
    init(_ pageNameStr: String) {
        switch pageNameStr {
        case "News":
            self = .news
        case "Front":
            self = .front
        case "New":
            self = .new
        case "Jobs":
            self = .jobs
        case "Ask HN":
            self = .asks
        case "Show HN":
            self = .shows
        case "Show HN (Latest)":
            self = .newshows
        case "Active":
            self = .active
        case "Best":
            self = .best
        case "Noob":
            self = .noob
        default:
            self = .news
        }
    }


    var description: String {
        switch self {
        /// Home page
        case .news:
            return "News"
        // Today's front page
        case .front:
            return "Front"
        /// Latest submissions
        case .new:
            return "New"
        /// Jobs only (new first)
        case .jobs:
            return "Jobs"
        /// Asks only (new first)
        case .asks:
            return "Ask HN"
        /// Shows only (top)
        case .shows:
            return "Show HN"
        /// Shows only (latest)
        case .newshows:
            return "Show HN (Latest)"
        /// All news with most active discussion thread first
        case .active:
            return "Active"
        /// Highest (recent) score
        case .best:
            return "Best"
        /// More recent, only by new users
        case .noob:
            return "Noob"
        }
    }

    var iconName: String? {
        switch self {
        case .news:
            return "TopIcon"
        case .asks:
            return "AskIcon"
        case .jobs:
            return "JobsIcon"
        case .new:
            return "NewIcon"
        default:
            return nil
        }
    }

    var tabBarIcon: UIImage {
        var iconName: FontAwesome = .questionCircle

        switch self {
        /// Home page
        case .news:
            iconName = .globe
        // Today's front page
        case .front:
            iconName = .calendar
        /// Latest submissions
        case .new:
            iconName = .clock
        /// Jobs only (new first)
        case .jobs:
            iconName = .briefcase
        /// Asks only (new first)
        case .asks:
            iconName = .question
        /// Shows only (top)
        case .shows:
            iconName = .eye
        /// Shows only (latest)
        case .newshows:
            iconName = .eye
        /// All news with most active discussion thread first
        case .active:
            iconName = .fire
        /// Highest (recent) score
        case .best:
            iconName = .star
        /// More recent, only by new users
        case .noob:
            iconName = .child
        }

        return UIImage.fontAwesomeIcon(name: iconName, style: .solid,
                                       textColor: AppThemeProvider.shared.currentTheme.barForegroundColor,
                                       size: CGSize(width: 30, height: 30))
    }

    func tabBarItem(_ tag: Int) -> UITabBarItem {
        return UITabBarItem(title: self.description, image: self.tabBarIcon, tag: tag)
    }
}
