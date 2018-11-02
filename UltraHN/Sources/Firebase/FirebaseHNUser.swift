//
//  FirebaseHNUser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

public class FirebaseHNUser: HNUser {
    enum CodingKeys: String, CodingKey {
        case Username = "id"
        case Karma = "karma"
        case CreatedAt = "created"
        case About = "about"
        case SubmittedIDs = "submitted"
    }

    required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.Username = try container.decode(String.self, forKey: .Username)
        self.Karma = try container.decode(Int.self, forKey: .Karma)
        self.CreatedAt = try? container.decode(Date.self, forKey: .CreatedAt)
        self.About = try container.decode(String.self, forKey: .About)
        self.SubmittedIDs = try? container.decode([Int].self, forKey: .SubmittedIDs)
        self.SubmissionCount = self.SubmittedIDs?.count
    }
}
