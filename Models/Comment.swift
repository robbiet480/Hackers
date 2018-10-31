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

public class CommentModel: BaseHNItem {
    @objc dynamic var Post: PostModel?
    @objc dynamic var Level: Int = 0
    @objc dynamic var Visibility: VisibilityType = .Visible

    @objc enum VisibilityType: Int {
        case Visible = 3
        case Compact = 2
        case Hidden = 1
    }

    convenience init(_ comment: HNItem, _ post: PostModel? = nil) {
        self.init()

        self.ID = comment.ID

        if let post = post {
            self.Post = post
        }

        self.text = comment.Text
        self.author = comment.Author?.Username
        self.parentId.value = comment.ParentID

        self.Level = comment.Level
    }

    override var ItemPageTitle: String {
        return self.author! + "'s comment on Hacker News"
    }

    var ActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.ItemPageTitle, self.ItemURL], applicationActivities: nil)
    }

}
