//
//  FirebaseHNUser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import CodableFirebase

public class FirebaseHNUser: HNUser {
    enum CodingKeys: String, CodingKey {
        case Username = "id"
        case Karma = "karma"
        case CreatedAt = "created"
        case About = "about"
        case SubmittedIDs = "submitted"
    }
}
