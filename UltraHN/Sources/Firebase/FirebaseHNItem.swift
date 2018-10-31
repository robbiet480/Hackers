//
//  FirebaseHNItem.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

public class FirebaseHNItem: HNItem {
    enum CodingKeys: String, CodingKey {
        case Author = "by"
        case Title = "title"
        case Text = "text"
        case Score = "points"
        case ID = "id"
        case CreatedAt = "time"
        case `Type` = "type"
        case ChildrenIDs = "kids"
    }
}
