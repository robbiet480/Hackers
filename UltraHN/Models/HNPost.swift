//
//  HNPost.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftSoup

open class NewHNPost: NewHNItem {
    public var Rank: Int = 0
    public var Link: URL?
    public var Site: String?
    public var CommentCount: Int = 0

    public var Favorited: Bool = false

    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

//    override open var description: String {
//        return "HNPost: rank: \(self.Rank), type: \(self.Type.description), ID: \(self.ID) (dead: \(self.Dead)), author: \(self.Author) (new: \(self.AuthorIsNew)), score: \(self.Score), comments: \(self.CommentCount), title: \(self.Title), link: \(self.Link)"
//    }

    public static func ==(lhs: NewHNPost, rhs: NewHNPost) -> Bool {
        return lhs.ID == rhs.ID
    }
}

