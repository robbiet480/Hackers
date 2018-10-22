//
//  Realm+Initialization.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import RealmSwift

extension Realm {
    /// An in-memory data store, intended to be used in tests.
    public static let mock = {
        // swiftlint:disable:next force_try
        try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "Memory"))
    }

    /// The live data store, located in shared storage.
    public static let live: () -> Realm = {
        let fileManager = FileManager.default
        let storeDirectoryURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.io.robbie.Hackers")?
            .appendingPathComponent("dataStore", isDirectory: true)

        guard let directoryURL = storeDirectoryURL else {
            assertionFailure("Unable to get datastoreURL.")
            return Realm.mock()
        }

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                let attributes =
                    [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true,
                                                attributes: attributes)
            } catch {
                print("Error while attempting to create data store URL: \(error)")
            }
        }

        let storeURL =  directoryURL.appendingPathComponent("store.realm", isDirectory: false)
        let config = Realm.Configuration(fileURL: storeURL, schemaVersion: 4,
                                         migrationBlock: nil, deleteRealmIfMigrationNeeded: true)

        print("Realm is stored at", storeURL)

        // swiftlint:disable:next force_try
        return try! Realm(configuration: config)
    }
}
