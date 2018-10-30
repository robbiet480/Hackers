//
//  HNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

open class NewHNItem: NSObject, Codable {
    public var Author: String?
    public var AuthorIsNew: Bool = false
    public var Dead: Bool = false
    public var Flagged: Bool = false
    public var Title: String?
    public var Text: String?
    public var Score: Int?
    public var ID: Int = 0
    public var RelativeTime: String = ""
    public var CreatedAt: Date?
    public var `Type`: HNItemType = .story
    public var ParentID: Int?
    public var StoryID: Int?

    public var Children: [NewHNItem]?
    public var ChildrenIDs: [Int]?
    public var TotalChildren: Int = 0
    public var Level: Int = 0

    public var Upvoted: Bool = false
    public var UpvoteAuthKey: String?
    public var VoteAuthKey: String?

    enum CodingKeys: String, CodingKey {
        case Author = "author"
        case Title = "title"
        case Text = "text"
        case Score = "points"
        case ID = "id"
        case CreatedAt = "created_at"
        case `Type` = "type"
        case ParentID = "parent_id"
        case StoryID = "story_id"
        case Children = "children"
    }

    public enum HNItemType: String, CaseIterable, Codable {
        case story = "story"
        case askHN = "ask_hn"
        case jobs = "job"
        case comment = "comment"
        case showHN = "show_hn"
        case poll = "poll"
        case pollOption = "poll_opt"

        var description: String {
            switch self {
            case .story:
                return "Story"
            case .askHN:
                return "Ask HN"
            case .jobs:
                return "Jobs"
            case .comment:
                return "Comment"
            case .showHN:
                return "Show HN"
            case .poll:
                return "Poll"
            case .pollOption:
                return "Poll option"
            }
        }
    }

//    override open var description: String {
//        return "HNItem: type: \(self.Type.description), ID: \(self.ID), author: \(self.Author), score: \(self.Score), createdAt: \(self.CreatedAt), comments: \(self.TotalChildren), title: \(self.Title)"
//    }

    public func collectChildren(_ level: Int = 0) -> [NewHNItem] {
        var childArray: [NewHNItem] = [self]

        if let children = self.Children {
            for child in children {
                child.Level = level
                childArray = childArray + child.collectChildren(level + 1)
            }
        }

        self.TotalChildren = self.TotalChildren + childArray.count - 1

        return childArray
    }
}

// MARK: - Alamofire response handlers

public extension Alamofire.DataRequest {
    fileprivate func decodableResponseSerializer<T: Decodable>() -> DataResponseSerializer<T> {
        return DataResponseSerializer { _, response, data, error in
            guard error == nil else { return .failure(error!) }

            guard let data = data else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }

            return Result { try newJSONDecoder().decode(T.self, from: data) }
        }
    }

    @discardableResult
    fileprivate func responseDecodable<T: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: decodableResponseSerializer(), completionHandler: completionHandler)
    }

    @discardableResult
    public func responseNewHNItem(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<NewHNItem>) -> Void) -> Self {
        return responseDecodable(queue: queue, completionHandler: completionHandler)
    }

    public func responseNewHNItem(queue: DispatchQueue? = nil) -> Promise<(item: NewHNItem, response: PMKAlamofireDataResponse)> {
        return Promise { seal in
            responseNewHNItem(queue: queue) { response in
                switch response.result {
                case .success(let value):
                    seal.fulfill((value, PMKAlamofireDataResponse(response)))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

