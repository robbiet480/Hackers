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

public class AlgoliaHNItem: HNItem {
    private enum CodingKeys: String, CodingKey {
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

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // let superDecoder = try container.superDecoder()
        // try super.init(from: superDecoder)
        super.init()

        self.Author = HNUser(username: try container.decode(String.self, forKey: .Author))
        self.Title = try? container.decode(String.self, forKey: .Title)
        self.Text = try? container.decode(String.self, forKey: .Text)
        self.Score = try? container.decode(Int.self, forKey: .Score)
        self.ID = try container.decode(Int.self, forKey: .ID)
        self.CreatedAt = try? container.decode(Date.self, forKey: .CreatedAt)
        self.`Type` = try container.decode(HNItemType.self, forKey: .`Type`)
        self.ParentID = try? container.decode(Int.self, forKey: .ParentID)
        self.StoryID = try? container.decode(Int.self, forKey: .StoryID)
        if let children = try? container.decode([AlgoliaHNItem].self, forKey: .Children) {
            self.Children = children
            self.TotalChildren = children.count
        }
    }
}
