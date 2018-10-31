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

public class AlgoliaHNUser: HNUser {
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

    required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.Username = try container.decode(String.self, forKey: .Username)
        self.Karma = try container.decode(Int.self, forKey: .Karma)
        self.CreatedAt = try? container.decode(Date.self, forKey: .CreatedAt)
        self.About = try? container.decode(String.self, forKey: .About)
        self.CommentCount = try? container.decode(Int.self, forKey: .CommentCount)
        self.Average = try? container.decode(Double.self, forKey: .Average)
        self.Delay = try? container.decode(Double.self, forKey: .Delay)
        self.SubmissionCount = try? container.decode(Int.self, forKey: .SubmissionCount)
        self.UpdatedAt = try? container.decode(Date.self, forKey: .UpdatedAt)
    }
}
