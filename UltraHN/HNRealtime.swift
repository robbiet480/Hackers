//
//  HNRealtime.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CodableFirebase

class HNRealtime {
    public let PageUpdatedNotificationName = Notification.Name("UltraHN.PageUpdated")
    public let PostUpdatedNotificationName = Notification.Name("UltraHN.PostUpdated")
    public let UserUpdatedNotificationName = Notification.Name("UltraHN.UserUpdated")
    public let CommentUpdatedNotificationName = Notification.Name("UltraHN.CommentUpdated")

    public static let shared: HNRealtime = HNRealtime()

    public var IsMonitoring: Bool = false {
        didSet {
            if self.IsMonitoring == false {
                self.dbRef.removeAllObservers()
                self.handles = [:]
            }
        }
    }

    public let dbRef: DatabaseReference = FirebaseDataSource.dbRef

    public var handles: [DatabaseReference: DatabaseHandle] = [:]

    public enum MonitorType: Int, CaseIterable {
        case Post
        case Comment
        case User
        case Page
    }

    public func Monitor(_ itemID: Int, _ itemType: HNItem.HNItemType) -> DatabaseHandle? {
        let monitorType: MonitorType = itemType == .comment ? .Comment : .Post

        return self.monitor(monitorType, self.dbRef.child("item/" + itemID.description))
    }

    public func Monitor(_ username: String) -> DatabaseHandle? {
        return self.monitor(.User, self.dbRef.child("user/" + username))
    }

    public func Monitor(_ pageName: HNScraper.Page) -> DatabaseHandle? {
        guard let path = pageName.firebasePath else { return nil }

        return self.monitor(.Page, self.dbRef.child(path))
    }

    public func Unmonitor(_ itemID: Int) -> Bool {
        return self.unmonitor(self.dbRef.child("item/" + itemID.description))
    }

    public func Unmonitor(_ username: String) -> Bool {
        return self.unmonitor(self.dbRef.child("user/" + username))
    }

    public func Unmonitor(_ pageName: HNScraper.Page) -> Bool {
        guard let path = pageName.firebasePath else { return false }

        return self.unmonitor(self.dbRef.child(path))
    }

    private func monitor(_ monitorType: MonitorType, _ itemRef: DatabaseReference) -> DatabaseHandle? {
        guard HNScraper.shared.automaticallyMonitorItems == true else { return nil }

        guard self.handles[itemRef] == nil else { return self.handles[itemRef] }

        print("Beginning to monitor", itemRef)

        let refHandle = itemRef.observe(.value, with: self.HandleUpdate(monitorType), withCancel: self.HandleCancel)

        self.handles[itemRef] = refHandle

        return refHandle
    }

    private func unmonitor(_ itemRef: DatabaseReference) -> Bool {
        guard self.handles[itemRef] != nil else { return true }

        guard let handle = self.handles[itemRef] else { return false }

        print("Ending monitoring of", itemRef)

        self.dbRef.removeObserver(withHandle: handle)

        return true
    }

    public func HandleUpdate(_ monitorType: MonitorType) -> ((DataSnapshot) -> Void) {
        return { snapshot in
            guard let value = snapshot.value else { print("Got an empty snapshot!"); return }

            do {
                switch monitorType {
                case .Post:
                    print("Got snapshot", snapshot.ref)
                    let decoded = try FirebaseDecoder().decode(FirebaseHNPost.self, from: value)
                    NotificationCenter.default.post(name: self.PostUpdatedNotificationName,
                                                    object: decoded, userInfo: ["multiple": false,
                                                                                "id": decoded.ID,
                                                                                "type": decoded.Type])
                    return
                case .Comment:
                    let decoded = try FirebaseDecoder().decode(FirebaseHNItem.self, from: value)
                    NotificationCenter.default.post(name: self.CommentUpdatedNotificationName,
                                                    object: decoded, userInfo: ["multiple": false,
                                                                                "id": decoded.ID])
                    return
                case .User:
                    let decoded = try FirebaseDecoder().decode(FirebaseHNUser.self, from: value)
                    NotificationCenter.default.post(name: self.UserUpdatedNotificationName,
                                                    object: decoded, userInfo: ["username": decoded.Username])
                    return
                case .Page:
                    let decoded = try FirebaseDecoder().decode([Int].self, from: value)
                    NotificationCenter.default.post(name: self.PageUpdatedNotificationName,
                                                    object: decoded, userInfo: nil)
                    return
                }
            } catch let error {
                print("Got error while handling snapshot update!", error)
            }
        }
    }

    public var HandleCancel: ((Error) -> Void) {
        return { error in
            print("Received error from Firebase", error)
        }
    }
}
