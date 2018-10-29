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
import PromiseKit
import Alamofire
import SwiftSoup

extension HNScraper {
    public func getItemAuthString(_ itemID: Int) -> Promise<String?> {
        let itemURL = "https://news.ycombinator.com/item?id=" + String(itemID)
        return firstly {
            Alamofire.request(itemURL).responseString()
        }.then { html, _ -> Promise<String?> in
            return Promise.value(try SwiftSoup.parse(html).select(".fatitem .votelinks a").first()!.attr("href").description)
        }
    }

    public func voteItem(_ voteURL: String, _ itemID: Int, action: HNScraper.VoteAction) -> Promise<Void> {
        return Promise { seal in
            let url = HNScraper.baseUrl + voteURL.replacingOccurrences(of: "&amp;", with: "&")
            HNScraper.shared.voteOnHNObject(AtUrl: url, objectId: String(itemID), action: action) { (error) in
                seal.resolve(error)
            }
        }
    }

    public func voteItem(_ itemID: Int, action: HNScraper.VoteAction) -> Promise<String?> {
        return self.getItemAuthString(itemID).then { authStr in
            self.voteItem(authStr!, itemID, action: action).then {
                return Promise.value(authStr)
            }
        }
    }

    public func getPost(_ postID: Int) -> Promise<HNPost> {
        return Promise { seal in
            HNScraper.shared.getPost(ById: String(postID), completion: { (post, _, error) in
                seal.resolve(post, error)
            })
        }
    }

    public func upvotePost(_ post: HNPost) -> Promise<Void> {
        return Promise { seal in
            HNScraper.shared.upvote(Post: post, completion: { (error) in
                seal.resolve(error)
            })
        }
    }

    public func downvotePost(_ post: HNPost) -> Promise<Void> {
        return Promise { seal in
            HNScraper.shared.unvote(Post: post, completion: { (error) in
                seal.resolve(error)
            })
        }
    }

    public func upvotePostForID(_ postID: Int) -> Promise<Void> {
        return self.getPost(postID).then { self.upvotePost($0) }
    }

    public func downvotePostForID(_ postID: Int) -> Promise<Void> {
        return self.getPost(postID).then { self.downvotePost($0) }
    }
}

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

extension HNUser {
    public var description: String {
        return "HNUser: <\(self.username!)>"
    }
}

extension String {

    func slice(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}
