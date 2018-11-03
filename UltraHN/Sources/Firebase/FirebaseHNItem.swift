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
        case Score = "score"
        case ID = "id"
        case CreatedAt = "time"
        case `Type` = "type"
        case ChildrenIDs = "kids"
        case TotalChildren = "descendants"
    }

    required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.Author = HNUser(username: try container.decode(String.self, forKey: .Author))
        self.Title = try? container.decode(String.self, forKey: .Title)
        self.Text = try? container.decode(String.self, forKey: .Text)
        self.Score = try? container.decode(Int.self, forKey: .Score)
        self.ID = try container.decode(Int.self, forKey: .ID)
        self.CreatedAt = try? container.decode(Date.self, forKey: .CreatedAt)
        self.`Type` = try container.decode(HNItemType.self, forKey: .`Type`)
        self.TotalChildren = try container.decode(Int.self, forKey: .TotalChildren)
        if let childIDs = try? container.decode([Int].self, forKey: .ChildrenIDs) {
            self.ChildrenIDs = childIDs
            if self.TotalChildren == 0 && childIDs.count > 0 {
                self.TotalChildren = childIDs.count
            }
        }
    }
}