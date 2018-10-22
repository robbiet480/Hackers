//
//  Comment.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import Kingfisher
import OpenGraph

class CommentModel: Object {
    @objc dynamic var Post: PostModel?
    @objc dynamic var `Type`: HNCommentType = .default
    @objc dynamic var Text: String = ""
    @objc dynamic var Username: String = ""
    @objc dynamic var ID: Int = 0
    let ParentID = RealmOptional<Int>()
    @objc dynamic var TimeCreatedString: String = ""
    @objc dynamic var ReplyURLString: String = ""
    @objc dynamic var Level: Int = 0
    let Links = List<CommentLink>()
    @objc dynamic var UpvoteURLAddition: String = ""
    @objc dynamic var DownvoteURLAddition: String = ""
    @objc dynamic var Visibility: VisibilityType = .Visible

    @objc dynamic var CreatedAt: Date = Date()

    @objc dynamic var ReadAt: Date?

    @objc enum VisibilityType: Int {
        case Visible = 3
        case Compact = 2
        case Hidden = 1
    }

    override static func primaryKey() -> String? {
        return "ID"
    }

    convenience init(_ comment: HNComment, _ post: PostModel? = nil) {
        self.init()

        if let strCommentID = comment.commentId, let commentID = Int(string: strCommentID) {
            self.ID = commentID
        } else {
            print("No comment ID for a comment in post!", post)
            print("Comment ID", comment, comment.commentId)
            return
        }


        if let post = post {
            self.Post = post
        }

        self.`Type` = comment.type
        self.Text = comment.text
        self.Username = comment.username
        if let parentID = comment.parentID {
            self.ParentID.value = Int(string: parentID)
        }
        self.TimeCreatedString = comment.timeCreatedString

        if let replyURLString = comment.replyURLString {
            self.ReplyURLString = replyURLString
        } else {
            print("No reply URL string for comment", comment, self.ID)
        }

        self.Level = Int(comment.level)
        if let upvoteURLAddition = comment.upvoteURLAddition {
            self.UpvoteURLAddition = upvoteURLAddition
        }
        if let downvoteURLAddition = comment.downvoteURLAddition {
            self.DownvoteURLAddition = downvoteURLAddition
        }

        if let links = comment.links as? [HNCommentLink] {
            self.Links.append(objectsIn: links.map({ CommentLink($0) }))
        }
    }

    var ReplyURL: URL {
        return URL(string: self.ReplyURLString)!
    }

    var Link: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.ID.description)!
    }

    var PageTitle: String {
        return self.Username + "'s comment on Hacker News"
    }

    var ActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.PageTitle, self.Link], applicationActivities: nil)
    }

}

class CommentLink: Object {
    @objc dynamic var URLString: String = ""
    @objc dynamic var HNLink: Bool = false

    convenience init(_ commentLink: HNCommentLink) {
        self.init()

        self.URLString = commentLink.url.description
        self.HNLink = commentLink.type == .HN
    }
}
