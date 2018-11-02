//
//  BaseHNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/23/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift

// Originally from https://github.com/omaralbeik/HNClient/blob/master/Source/Model/HNItem.swift

/// Story, comment, job, Ask HN, poll or poll part
public class BaseHNItem: Object {

    /// Item's unique id.
    @objc dynamic var ID: Int = 0

    /// True if the item is deleted.
    @objc dynamic var isDeleted: Bool = false

    /// Type of item.
    @objc dynamic var type: String = ""

    /// Username of the item's author.
    @objc dynamic var author: String?

    /// Creation date of the item.
    @objc dynamic var time: Date?

    /// The comment, story or poll text. HTML.
    @objc dynamic var text: String?

    /// True if the item is dead.
    @objc dynamic var isDead: Bool = false

    /// Comment's parent: either another comment or the relevant story.
    var parentId = RealmOptional<Int>()

    /// Pollopt's associated poll.
    var pollId = RealmOptional<Int>()

    /// IDs of the item's comments, in ranked display order.
    var kidsIds = List<Int>()

    /// Story's score, or the votes for a pollopt.
    var score = RealmOptional<Int>()

    /// The title of the story, poll or job.
    @objc dynamic var title: String?

    /// List of related pollopts, in display order.
    var pollParts = List<Int>()

    /// In the case of stories or polls, the total comment count.
    @objc dynamic var descendants: Int = 0

    /// Whether the user upvoted. If NO, they downvoted
    var Upvoted = RealmOptional<Bool>()

    /// The authentication key for a vote. Needed to unvote for 1 hour after upvote.
    @objc dynamic var VoteKey: String?

    /// The time at which the user took a vote action
    @objc dynamic var VotedAt: Date?

    /// The date when this item was imported to the Realm.
    @objc dynamic var CreatedAt: Date = Date()

    /// The date when this item was marked as read.
    @objc dynamic var ReadAt: Date?

    override public static func primaryKey() -> String? {
        return "ID"
    }

    public static func ==(lhs: BaseHNItem, rhs: BaseHNItem) -> Bool {
        return lhs.ID == rhs.ID
    }

    var ItemURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + String(self.ID))!
    }

    var ItemPageTitle: String {
        return self.title! + " | Hacker News"
    }
}
