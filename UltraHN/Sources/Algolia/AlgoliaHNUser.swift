//
//  AlgoliaHNUser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

open class AlgoliaHNUser: NewHNUser {
    enum CodingKeys: String, CodingKey {
        case Username = "username"
        case Karma = "karma"
        case CreatedAt = "created_at"
        case About = "about"
        case CommentCount = "comment_count"
        case Average = "avg"
        case Delay = "delay"
        case SubmissionCount = "submission_count"
        case UpdatedAt = "updated_at"
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
    public func responseAlgoliaHNUser(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<AlgoliaHNUser>) -> Void) -> Self {
        return responseDecodable(queue: queue, completionHandler: completionHandler)
    }

    public func responseAlgoliaHNUser(queue: DispatchQueue? = nil) -> Promise<(user: AlgoliaHNUser, response: PMKAlamofireDataResponse)> {
        return Promise { seal in
            responseAlgoliaHNUser(queue: queue) { response in
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
