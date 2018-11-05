//
//  AlgoliaAPI.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/4/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

// To parse the JSON, add this file to your project and do:
//
//   let algoliaSearchResult = try? newJSONDecoder().decode(AlgoliaSearchResult.self, from: jsonData)

import Foundation

public class AlgoliaItemsSearchResult: Codable {
    public let hits: [AlgoliaItemHit]
    public let nbHits: Int
    public let page: Int
    public let nbPages: Int
    public let hitsPerPage: Int
    public let processingTimeMS: Int
    public let exhaustiveNbHits: Bool
    public let query: String?
    public let params: String?
    public let queryID: String?
    public let serverUsed: String?
    public let indexUsed: String?
    public let parsedQuery: String?
    public let timeoutCounts: Bool?
    public let timeoutHits: Bool?

    enum CodingKeys: String, CodingKey {
        case hits = "hits"
        case nbHits = "nbHits"
        case page = "page"
        case nbPages = "nbPages"
        case hitsPerPage = "hitsPerPage"
        case processingTimeMS = "processingTimeMS"
        case exhaustiveNbHits = "exhaustiveNbHits"
        case query = "query"
        case params = "params"
        case queryID = "queryID"
        case serverUsed = "serverUsed"
        case indexUsed = "indexUsed"
        case parsedQuery = "parsedQuery"
        case timeoutCounts = "timeoutCounts"
        case timeoutHits = "timeoutHits"
    }

    public init(hits: [AlgoliaItemHit], nbHits: Int, page: Int, nbPages: Int, hitsPerPage: Int, processingTimeMS: Int,
                exhaustiveNbHits: Bool, query: String, params: String, queryID: String, serverUsed: String,
                indexUsed: String, parsedQuery: String, timeoutCounts: Bool, timeoutHits: Bool) {
        self.hits = hits
        self.nbHits = nbHits
        self.page = page
        self.nbPages = nbPages
        self.hitsPerPage = hitsPerPage
        self.processingTimeMS = processingTimeMS
        self.exhaustiveNbHits = exhaustiveNbHits
        self.query = query
        self.params = params
        self.queryID = queryID
        self.serverUsed = serverUsed
        self.indexUsed = indexUsed
        self.parsedQuery = parsedQuery
        self.timeoutCounts = timeoutCounts
        self.timeoutHits = timeoutHits
    }
}

public class AlgoliaUsersSearchResult: Codable {
    public let hits: [AlgoliaUserHit]
    public let nbHits: Int
    public let page: Int
    public let nbPages: Int
    public let hitsPerPage: Int
    public let processingTimeMS: Int
    public let exhaustiveNbHits: Bool
    public let query: String?
    public let params: String?
    public let queryID: String?
    public let serverUsed: String?
    public let indexUsed: String?
    public let parsedQuery: String?
    public let timeoutCounts: Bool?
    public let timeoutHits: Bool?

    enum CodingKeys: String, CodingKey {
        case hits = "hits"
        case nbHits = "nbHits"
        case page = "page"
        case nbPages = "nbPages"
        case hitsPerPage = "hitsPerPage"
        case processingTimeMS = "processingTimeMS"
        case exhaustiveNbHits = "exhaustiveNbHits"
        case query = "query"
        case params = "params"
        case queryID = "queryID"
        case serverUsed = "serverUsed"
        case indexUsed = "indexUsed"
        case parsedQuery = "parsedQuery"
        case timeoutCounts = "timeoutCounts"
        case timeoutHits = "timeoutHits"
    }

    public init(hits: [AlgoliaUserHit], nbHits: Int, page: Int, nbPages: Int, hitsPerPage: Int, processingTimeMS: Int,
                exhaustiveNbHits: Bool, query: String, params: String, queryID: String, serverUsed: String,
                indexUsed: String, parsedQuery: String, timeoutCounts: Bool, timeoutHits: Bool) {
        self.hits = hits
        self.nbHits = nbHits
        self.page = page
        self.nbPages = nbPages
        self.hitsPerPage = hitsPerPage
        self.processingTimeMS = processingTimeMS
        self.exhaustiveNbHits = exhaustiveNbHits
        self.query = query
        self.params = params
        self.queryID = queryID
        self.serverUsed = serverUsed
        self.indexUsed = indexUsed
        self.parsedQuery = parsedQuery
        self.timeoutCounts = timeoutCounts
        self.timeoutHits = timeoutHits
    }
}

public class AlgoliaUserHit: Codable {
    public let id: Int
    public let username: String
    public let about: String?
    public let karma: Int
    public let createdAt: Date?
    public let avg: Double?
    public let delay: Double?
    public let submitted: Int?
    public let updatedAt: Date?
    public let submissionCount: Int?
    public let commentCount: Int?
    public let createdAtTimestamp: TimeInterval
    public var highlightResult: [String: AlgoliaHighlightResult] = [:]

    lazy var objectID: Int = {
        Int(self.objectIDStr)!
    }()

    private var objectIDStr: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case username = "username"
        case about = "about"
        case karma = "karma"
        case createdAt = "created_at"
        case avg = "avg"
        case delay = "delay"
        case submitted = "submitted"
        case updatedAt = "updated_at"
        case submissionCount = "submission_count"
        case commentCount = "comment_count"
        case createdAtTimestamp = "created_at_i"
        case objectIDStr = "objectID"
        case highlightResult = "_highlightResult"
    }

    public init(id: Int, username: String, about: String, karma: Int, createdAt: Date, avg: Double, delay: Double?,
                submitted: Int, updatedAt: Date, submissionCount: Int, commentCount: Int, createdAtTimestamp: TimeInterval,
                objectID: String, highlightResult: [String: AlgoliaHighlightResult]) {
        self.id = id
        self.username = username
        self.about = about
        self.karma = karma
        self.createdAt = createdAt
        self.avg = avg
        self.delay = delay
        self.submitted = submitted
        self.updatedAt = updatedAt
        self.submissionCount = submissionCount
        self.commentCount = commentCount
        self.createdAtTimestamp = createdAtTimestamp
        self.objectIDStr = objectID
        self.highlightResult = highlightResult
    }

    var hnUser: HNUser {
        return HNUser(about: self.about, average: self.avg, commentCount: self.commentCount, createdAt: self.createdAt,
                      delay: self.delay, isNew: false, isYC: false, karma: self.karma,
                      submissionCount: self.submissionCount, updatedAt: self.updatedAt, username: self.username)
    }
}

public class AlgoliaItemHit: Codable {
    public let createdAt: Date?
    public let title: String?
    public let url: String?
    public let author: String?
    public let points: Int?
    public let storyText: String?
    public let commentText: String?
    public let numComments: Int?
    public let storyID: Int?
    public let storyTitle: String?
    public let storyURL: String?
    public let parentID: Int?
    public let createdAtTimestamp: TimeInterval
    public let tags: [String]
    public var highlightResult: [String: AlgoliaHighlightResult] = [:]
    public let rankingInfo: AlgoliaRankingInfo?

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
        case highlightResult = "_highlightResult"
        case rankingInfo = "_rankingInfo"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.title = try? container.decode(String.self, forKey: .title)
        self.url = try? container.decode(String.self, forKey: .url)
        self.author = try container.decode(String.self, forKey: .author)
        self.points = try? container.decode(Int.self, forKey: .points)
        self.storyText = try? container.decode(String.self, forKey: .storyText)
        self.commentText = try? container.decode(String.self, forKey: .commentText)
        self.numComments = try? container.decode(Int.self, forKey: .numComments)
        self.storyID = try? container.decode(Int.self, forKey: .storyID)
        self.storyTitle = try? container.decode(String.self, forKey: .storyTitle)
        self.storyURL = try? container.decode(String.self, forKey: .storyURL)
        self.parentID = try? container.decode(Int.self, forKey: .parentID)
        self.createdAtTimestamp = try container.decode(TimeInterval.self, forKey: .createdAtTimestamp)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.objectIDStr = try container.decode(String.self, forKey: .objectIDStr)
        self.highlightResult = try container.decode([String: AlgoliaHighlightResult].self, forKey: .highlightResult)
        self.rankingInfo = try? container.decode(AlgoliaRankingInfo.self, forKey: .rankingInfo)
    }

    public init(createdAt: Date, title: String, url: String, author: String, points: Int, storyText: String?,
                commentText: String?, numComments: Int, storyID: Int?, storyTitle: String?, storyURL: String?,
                parentID: Int?, createdAtTimestamp: TimeInterval, tags: [String], objectID: String,
                highlightResult: [String: AlgoliaHighlightResult], rankingInfo: AlgoliaRankingInfo) {
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
        self.highlightResult = highlightResult
        self.rankingInfo = rankingInfo
    }

    var hnItem: HNPost {
        let item = HNPost()
        item.ID = self.objectID
        if let createdAt = self.createdAt {
            item.CreatedAt = createdAt
        }

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
        // item.Title = self.storyTitle
        item.ParentID = self.parentID

        // Item has a URL, must be a post not comment
        if let urlStr = self.url, let url = URL(string: urlStr) {
            item.Link = url
        }

        return item
    }
}

public class AlgoliaHighlightResult: Codable {
    public let value: String
    public let matchLevel: AlgoliaMatchLevel
    public let matchedWords: [String]
    public let fullyHighlighted: Bool?

    enum CodingKeys: String, CodingKey {
        case value = "value"
        case matchLevel = "matchLevel"
        case matchedWords = "matchedWords"
        case fullyHighlighted = "fullyHighlighted"
    }

    public init(value: String, matchLevel: AlgoliaMatchLevel, matchedWords: [String], fullyHighlighted: Bool?) {
        self.value = value
        self.matchLevel = matchLevel
        self.matchedWords = matchedWords
        self.fullyHighlighted = fullyHighlighted
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.value = try container.decode(String.self, forKey: .value)
        self.matchLevel = try container.decode(AlgoliaMatchLevel.self, forKey: .matchLevel)
        self.matchedWords = try container.decode([String].self, forKey: .matchedWords)
        self.fullyHighlighted = try? container.decode(Bool.self, forKey: .fullyHighlighted)
    }
}

public enum AlgoliaMatchLevel: String, Codable {
    case none = "none"
    case partial = "partial"
    case full = "full"
}

public class AlgoliaRankingInfo: Codable {
    public let nbTypos: Int
    public let firstMatchedWord: Int
    public let proximityDistance: Int
    public let userScore: Int
    public let geoDistance: Int
    public let geoPrecision: Int
    public let nbExactWords: Int
    public let words: Int
    public let filters: Int

    enum CodingKeys: String, CodingKey {
        case nbTypos = "nbTypos"
        case firstMatchedWord = "firstMatchedWord"
        case proximityDistance = "proximityDistance"
        case userScore = "userScore"
        case geoDistance = "geoDistance"
        case geoPrecision = "geoPrecision"
        case nbExactWords = "nbExactWords"
        case words = "words"
        case filters = "filters"
    }

    public init(nbTypos: Int, firstMatchedWord: Int, proximityDistance: Int, userScore: Int, geoDistance: Int, geoPrecision: Int, nbExactWords: Int, words: Int, filters: Int) {
        self.nbTypos = nbTypos
        self.firstMatchedWord = firstMatchedWord
        self.proximityDistance = proximityDistance
        self.userScore = userScore
        self.geoDistance = geoDistance
        self.geoPrecision = geoPrecision
        self.nbExactWords = nbExactWords
        self.words = words
        self.filters = filters
    }

    /*public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.nbTypos = try container.decode(Int.self, forKey: .nbTypos)
        self.firstMatchedWord = try container.decode(Int.self, forKey: .firstMatchedWord)
        self.proximityDistance = try container.decode(Int.self, forKey: .proximityDistance)
        self.userScore = try container.decode(Int.self, forKey: .userScore)
        self.geoDistance = try container.decode(Int.self, forKey: .geoDistance)
        self.geoPrecision = try container.decode(Int.self, forKey: .geoPrecision)
        self.nbExactWords = try container.decode(Int.self, forKey: .nbExactWords)
        self.words = try container.decode(Int.self, forKey: .words)
        self.filters = try container.decode(Int.self, forKey: .filters)
    }*/
}
