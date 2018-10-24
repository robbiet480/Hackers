//
//  Comment.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import Kingfisher
import OpenGraph
import HNScraper

class CommentModel: HNItem {
    @objc dynamic var Post: PostModel?
    @objc dynamic var Level: Int = 0
    let Links = List<String>()
    @objc dynamic var UpvoteURLAddition: String = ""
    @objc dynamic var DownvoteURLAddition: String = ""
    @objc dynamic var Visibility: VisibilityType = .Visible

    @objc enum VisibilityType: Int {
        case Visible = 3
        case Compact = 2
        case Hidden = 1
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
    }

    convenience init(_ comment: HNComment, _ post: PostModel? = nil) {
        self.init()

        if let strCommentID = comment.id, let commentID = Int(string: strCommentID) {
            self.ID = commentID
        } else {
            //print("No comment ID for a comment in post!", post)
            //print("Comment ID", comment, comment.id)
            return
        }

        if let post = post {
            self.Post = post
        }

        self.text = comment.text.htmlDecoded
        self.author = comment.username
        if let parentID = comment.parentId {
            self.parentId.value = Int(string: parentID)
        }

        self.Level = Int(comment.level)
        if let upvoteURLAddition = comment.upvoteUrl {
            self.UpvoteURLAddition = upvoteURLAddition
        }
        if let downvoteURLAddition = comment.downvoteUrl {
            self.DownvoteURLAddition = downvoteURLAddition
        }

        if let links = comment.links {
            self.Links.append(objectsIn: links.map({ $0 }))
        }
    }

    override var ItemPageTitle: String {
        return self.author! + "'s comment on Hacker News"
    }

    var ActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.ItemPageTitle, self.ItemURL], applicationActivities: nil)
    }

}
