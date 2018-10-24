//
//  HNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/23/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import ObjectMapperAdditions
import FirebaseDatabase

// Originally from https://github.com/omaralbeik/HNClient/blob/master/Source/Model/HNItem.swift

let HTMLTextTransform = TransformOf<String, String>(fromJSON: {
    String($0!).htmlDecoded
}, toJSON: {
    $0.map { String($0) }
})

/// Story, comment, job, Ask HN, poll or poll part
public class HNItem: Object, StaticMappable {
    /// Item's unique id.
    @objc dynamic var ID: Int = 0

    /// True if the item is deleted.
    @objc dynamic var isDeleted: Bool = false

    /// Type of item.
    @objc dynamic var type: HNItemType = .story

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

    /// The date when this item was imported to the Realm.
    @objc dynamic var CreatedAt: Date = Date()

    /// The date when this item was marked as read.
    @objc dynamic var ReadAt: Date?

    public static func objectForMapping(map: Map) -> BaseMappable? {
        guard let strType: String = map["type"].value() else {
            print("Type is not HNItemType")
            return nil
        }

        switch HNItemType(strType) {
        case .story:
            return PostModel()
        case .comment:
            return CommentModel()
        default:
            return HNItem()
        }
    }

    public func mapping(map: Map) {
        ID                <- map["id"]
        isDeleted         <- map["deleted"]
        type              <- (map["type"], EnumTransform<HNItemType>())
        author            <- map["by"]
        time              <- (map["time"], DateTransform())
        text              <- (map["text"], HTMLTextTransform)
        isDead            <- map["dead"]
        parentId          <- (map["parent"], RealmOptionalTransform())
        pollId            <- (map["poll"], RealmOptionalTransform())
        kidsIds           <- (map["kids"], RealmTypeCastTransform())
        score.value       <- map["score"]
        title             <- map["title"]
        pollParts         <- (map["parts"], RealmTypeCastTransform())
        descendants       <- map["descendants"]
    }

    override public static func primaryKey() -> String? {
        return "ID"
    }

    override public var description: String {
        return toJSONString(prettyPrint: true) ?? ""
    }

    public static func ==(lhs: HNItem, rhs: HNItem) -> Bool {
        return lhs.ID == rhs.ID
    }

    var ItemURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + String(self.ID))!
    }

    var ItemPageTitle: String {
        return self.title! + " | Hacker News"
    }

    var FirebaseDBRef: DatabaseReference {
        return HNFirebaseClient.shared.dbRef.child("item").child(String(self.ID))
    }

    /// Type of HNItem.
    ///
    /// - story: Story HN
    /// - ask: Ask HN
    /// - poll: Poll HN
    /// - job: Job HN
    /// - comment: Comment HN
    /// - pollOpt: Poll Opt
    @objc enum HNItemType: Int, CaseIterable {
        case story
        case ask
        case poll
        case job
        case comment
        case pollOpt

        init(_ str: String) {
            switch str {
            case "story":
                self = .story
            case "ask":
                self = .ask
            case "poll":
                self = .poll
            case "job":
                self = .job
            case "comment":
                self = .comment
            case "pollopt":
                self = .pollOpt
            default:
                self = .story
            }
        }

        var description: String {
            switch self {
            case .story:
                return "story"
            case .ask:
                return "ask"
            case .poll:
                return "poll"
            case .job:
                return "job"
            case .comment:
                return "comment"
            case .pollOpt:
                return "pollopt"
            }
        }
    }
}
