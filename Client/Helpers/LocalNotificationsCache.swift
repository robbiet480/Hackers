//
//  LocalNotificationsCache.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import FMDB
import libHN

final class LocalNotificationsCache {

    private static let sqlitePath: String = {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return "\(path)/read-notifications.sqlite"
    }()

    private let path: String
    private lazy var queue: FMDatabaseQueue = {
        return FMDatabaseQueue(path: self.path)!
    }()

    init(
        path: String = LocalNotificationsCache.sqlitePath
        ) {
        self.path = path
    }

    func update(
        notifications: [HNPost],
        completion: @escaping ([HNPost]) -> Void
        ) {
        guard notifications.count > 0 else {
            completion([])
            return
        }

        queue.inDatabase { db in
            let table = "seen"
            let apiCol = "apiID"
            let idCol = "id"

            var map = [String: HNPost]()
            notifications.forEach {
                let key = $0.postId!
                map[key] = $0
            }
            let apiIDs = map.keys.map { $0 }

            do {
                // attempt to create the table
                try db.executeUpdate(
                    "create table if not exists \(table) (\(idCol) integer primary key autoincrement, \(apiCol) text)",
                    values: nil
                )

                try db.executeUpdate("delete from \(table)", values: nil)

                // remove notifications that already exist
                let selectSanitized = map.keys.map { _ in "?" }.joined(separator: ", ")
                let rs = try db.executeQuery(
                    "select \(apiCol) from \(table) where \(apiCol) in (\(selectSanitized))",
                    values: apiIDs
                )
                while rs.next() {
                    if let key = rs.string(forColumn: apiCol) {
                        map.removeValue(forKey: key)
                    }
                }

                // only perform updates if there are new notifications
                if map.count > 0 {
                    // add latest notification ids in the db
                    let insertSanitized = map.keys.map { _ in "(?)" }.joined(separator: ", ")
                    try db.executeUpdate(
                        "insert into \(table) (\(apiCol)) values \(insertSanitized)",
                        values: map.keys.map { $0 }
                    )

                    // cap the local database to latest 1000 notifications
                    try db.executeUpdate(
                        "delete from \(table) where \(idCol) not in (select \(idCol) from \(table) order by \(idCol) desc limit 1000)",
                        values: nil
                    )
                }
            } catch {
                print("failed: \(error.localizedDescription)")
            }
            completion(map.values.map { $0 })
        }
    }

}
