//
//  ItemLog.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/2/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift

public class ItemLog: Object {
    @objc dynamic var ID: Int = 0
    @objc dynamic var NotifiedAt: Date? = nil
    @objc dynamic var CreatedAt: Date = Date()

    public override static func primaryKey() -> String? {
        return "ID"
    }

    convenience init(_ id: Int) {
        self.init()
        self.ID = id
        self.NotifiedAt = Date()
        self.CreatedAt = Date()
    }
}
