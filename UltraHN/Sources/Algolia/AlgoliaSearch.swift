//
//  AlgoliaSearch.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

class AlgoliaSearchResult: Codable {
    let hits: [AlgoliaHit]
    let totalHits: Int?
    let page: Int?
    let totalPages: Int?
    let hitsPerPage: Int?
    let processingTimeMS: Int?
    let totalHitsExhaustive: Bool?
    let query: String?
    let params: String?

    enum CodingKeys: String, CodingKey {
        case hits = "hits"
        case totalHits = "totalHits"
        case page = "page"
        case totalPages = "totalPages"
        case hitsPerPage = "hitsPerPage"
        case processingTimeMS = "processingTimeMS"
        case totalHitsExhaustive = "totalHitsExhaustive"
        case query = "query"
        case params = "params"
    }

    init(hits: [AlgoliaHit]?, totalHits: Int?, page: Int?, totalPages: Int?, hitsPerPage: Int?, processingTimeMS: Int?,
         totalHitsExhaustive: Bool?, query: String?, params: String?) {
        self.hits = hits != nil ? hits! : []
        self.totalHits = totalHits
        self.page = page
        self.totalPages = totalPages
        self.hitsPerPage = hitsPerPage
        self.processingTimeMS = processingTimeMS
        self.totalHitsExhaustive = totalHitsExhaustive
        self.query = query
        self.params = params
    }
}

class AlgoliaHit: Codable {
    let createdAt: Date?
    let title: String?
    let url: String?
    let author: String?
    let points: Int?
    let storyText: String?
    let commentText: String?
    let numComments: Int?
    let storyID: Int?
    let storyTitle: String?
    let storyURL: String?
    let parentID: Int?
    let createdAtTimestamp: TimeInterval?
    let tags: [String]?
    var highlightResults: [String: HighlightResult] = [:]

    lazy var objectID: Int = {
        Int(self.objectIDStr)!
    }()

    private var objectIDStr: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case title = "title"
        case url = "url"
        case author = "author"
        case points = "points"
        case storyText = "story_text"
        case commentText = "comment_text"
        case numComments = "num_comments"
        case storyID = "story_id"
        case storyTitle = "story_title"
        case storyURL = "story_url"
        case parentID = "parent_id"
        case createdAtTimestamp = "created_at_i"
        case tags = "_tags"
        case objectIDStr = "objectID"
        case highlightResults = "_highlightResult"
    }

    init(createdAt: Date?, title: String?, url: String?, author: String?, points: Int?, storyText: String?,
         commentText: String?, numComments: Int?, storyID: Int?, storyTitle: String?, storyURL: String?, parentID: Int?,
         createdAtTimestamp: TimeInterval?, tags: [String]?, objectID: String, highlightResults: [String: HighlightResult]?) {
        self.createdAt = createdAt
        self.title = title
        self.url = url
        self.author = author
        self.points = points
        self.storyText = storyText
        self.commentText = commentText
        self.numComments = numComments
        self.storyID = storyID
        self.storyTitle = storyTitle
        self.storyURL = storyURL
        self.parentID = parentID
        self.createdAtTimestamp = createdAtTimestamp
        self.tags = tags
        self.objectIDStr = objectID
        self.highlightResults = highlightResults ?? [:]
    }

    var hnItem: HNItem {
        let item = HNItem()
        item.ID = self.objectID
        item.CreatedAt = self.createdAt
        item.Title = self.title
        if let author = self.author {
            item.Author = HNUser(username: author)
        }
        item.Score = self.points
        if let text = self.storyText {
            item.Text = text
        }
        if let text = self.commentText {
            item.Text = text
        }
        if let number = self.numComments {
            item.TotalChildren = number
        }
        item.StoryID = self.storyID
        item.Title = self.storyTitle
        item.ParentID = self.parentID

        // Item has a URL, must be a post not comment
        if let urlStr = self.url, let url = URL(string: urlStr), let post = item as? HNPost {
            post.Link = url

            return post
        }

        return item
    }
}

class HighlightResult: Codable {
    let value: String?
    let matchLevel: MatchLevel?
    let matchedWords: [String]?
    let fullyHighlighted: Bool?

    enum CodingKeys: String, CodingKey {
        case value = "value"
        case matchLevel = "matchLevel"
        case matchedWords = "matchedWords"
        case fullyHighlighted = "fullyHighlighted"
    }

    init(value: String?, matchLevel: MatchLevel?, matchedWords: [String]?, fullyHighlighted: Bool?) {
        self.value = value
        self.matchLevel = matchLevel
        self.matchedWords = matchedWords
        self.fullyHighlighted = fullyHighlighted
    }
}

enum MatchLevel: String, Codable {
    case none = "none"
    case partial = "partial"
    case full = "full"
}
