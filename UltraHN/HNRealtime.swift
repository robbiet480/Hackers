//
//  HNRealtime.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import FirebaseDatabase

class HNRealtime {
    public let PostUpdatedNotificationName = Notification.Name("UltraHN.PostUpdated")
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

    public func Monitor(_ itemID: Int) -> DatabaseHandle {
        return self.monitor(self.dbRef.child("item/" + itemID.description))
    }

    public func Monitor(_ username: String) -> DatabaseHandle {
        return self.monitor(self.dbRef.child("user/" + username))
    }

    public func Monitor(_ pageName: HNScraper.Page) -> DatabaseHandle? {
        guard let path = pageName.firebasePath else { return nil }

        return self.monitor(self.dbRef.child(path))
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

    private func monitor(_ itemRef: DatabaseReference) -> DatabaseHandle {
        guard self.handles[itemRef] == nil else { return self.handles[itemRef]! }

        let refHandle = itemRef.observe(.value, with: self.HandleUpdate, withCancel: self.HandleCancel)

        self.handles[itemRef] = refHandle

        return refHandle
    }

    private func unmonitor(_ itemRef: DatabaseReference) -> Bool {
        guard self.handles[itemRef] != nil else { return true }

        guard let handle = self.handles[itemRef] else { return false }

        self.dbRef.removeObserver(withHandle: handle)

        return true
    }

    public var HandleUpdate: ((DataSnapshot) -> Void) {
        return { snapshot in
            print("Got snapshot", snapshot)
        }
    }

    public var HandleCancel: ((Error) -> Void) {
        return { error in
            print("Received error from Firebase", error)
        }
    }
}
