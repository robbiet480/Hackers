//
//  AlgoliaHNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

open class AlgoliaHNItem: NewHNItem {
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
    public func responseAlgoliaHNItem(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<AlgoliaHNItem>) -> Void) -> Self {
        return responseDecodable(queue: queue, completionHandler: completionHandler)
    }

    public func responseAlgoliaHNItem(queue: DispatchQueue? = nil) -> Promise<(item: AlgoliaHNItem, response: PMKAlamofireDataResponse)> {
        return Promise { seal in
            responseAlgoliaHNItem(queue: queue) { response in
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

