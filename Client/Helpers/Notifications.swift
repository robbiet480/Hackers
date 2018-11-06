//
//  Notifications.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Kingfisher
import UserNotifications
import MobileCoreServices.UTType
import RealmSwift

final class Notifications {

    static func check(callback: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    callback(false)
                case .authorized, .provisional, .notDetermined:
                    callback(true)
                }
            }
        }
    }

    static func configure(
        application: UIApplication = UIApplication.shared,
        permissionHandler: ((Bool) -> Void)? = nil
        ) {

        guard UserDefaults.standard.notificationsEnabled else {
            DispatchQueue.main.async {
                application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
            }
            permissionHandler?(false)
            return
        }

        let opts: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(options: opts, completionHandler: { (granted, _) in
            if granted {
                var notifActions: [NotificationActions] = [.OpenLink, .ShareComments, .ShareLink]

                if UserDefaults.standard.notificationTapOpensLink {
                    notifActions = [.OpenComments, .ShareComments, .ShareLink]
                }

                print("Registering POST notification category with actions", notifActions)

                let storyNotificationCategory = UNNotificationCategory(identifier: "POST",
                                                                       actions: notifActions.map { $0.action },
                                                                       intentIdentifiers: [],
                                                                       hiddenPreviewsBodyPlaceholder: "%u stories",
                                                                       options: .customDismissAction)

                UNUserNotificationCenter.current().setNotificationCategories([storyNotificationCategory])

                DispatchQueue.main.async {
                    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
                }
            }

            permissionHandler?(granted)
        })
    }

    func fetch(application: UIApplication, handler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard UserDefaults.standard.notificationsEnabled else {
            print("Notifications are disabled")

            DispatchQueue.main.async {
                application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
            }

            handler(.noData)
            return
        }

        HNScraper.shared.GetPage(.Home).done { items in
            guard let items = items else { handler(.noData); return }

            let previousIDs = Realm.live().objects(ItemLog.self).filter("NotifiedAt != nil").map { $0.ID }

            print("Got", previousIDs.count, "previously stored IDs")

            let postsMeetingCriteria: [HNPost] = items.filter({ item -> Bool in

                guard previousIDs.contains(item.ID) == false else { return false }

                guard item.Type == .job && UserDefaults.standard.notifyForJobs == false else {
                    print("No jobs allowed", item.ID)
                    return false
                }

                guard item.Score ?? 0 >= UserDefaults.standard.minimumPointsForNotification else {
                    print("Doesn't meet points", item.ID, item.Score)
                    return false
                }

                return true

            }).compactMap { $0 as? HNPost }

            print("Got", postsMeetingCriteria.count, "possible notifies")

            self.sendLocalPush(for: postsMeetingCriteria)

            handler(postsMeetingCriteria.count > 0 ? .newData : .noData)

        }.catch { error in
            print("Hit an error during background fetch to grab stories", error)
            handler(.failed)
            return
        }
    }

    private func sendLocalPush(for notifications: [HNPost]) {
        let center = UNUserNotificationCenter.current()
        notifications.forEach { post in
            print("Building notification for", post)
            let content = UNMutableNotificationContent()
            content.title = post.Title!

            if let text = post.Domain {
                content.subtitle = text
            }

            let postedAt = post.RelativeDateLong.lowercased()

            content.body = "Posted " + postedAt

            if let score = post.Score, let author = post.Author {
                content.body = score.description + " points, posted by " + author.Username + " " + postedAt
            }

            if post.Rank > 0 {
                content.body = "#" + String(post.Rank) + ", " + content.body
            }

            content.categoryIdentifier = "POST"
            content.userInfo = ["POST_ID": post.ID]

            getAttachmentForPost(post, handler: { (attachment) in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }

                let request = UNNotificationRequest(
                    identifier: post.IDString,
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                )
                center.add(request)

                let realm = Realm.live()
                try! realm.write {
                    realm.add(ItemLog(post.ID), update: true)
                }
            })
        }
    }

    func getAttachmentForPost(_ post: HNPost, handler: @escaping (UNNotificationAttachment?) -> Void) {
        let options = [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]

        let isCached = ImageCache.default.imageCachedType(forKey: post.ThumbnailCacheKey)
        if isCached.cached {
            handler(try? UNNotificationAttachment(identifier: post.IDString,
                                          url: post.ThumbnailFileURL,
                                          options: options as [NSObject: AnyObject]))
            return
        }

        post.Thumbnail(true) { (image) in
            guard image != nil else { handler(nil); return }

            handler(try? UNNotificationAttachment(identifier: post.IDString,
                                                  url: post.ThumbnailFileURL,
                                                  options: options as [NSObject: AnyObject]))
        }
    }

}

public enum NotificationActions: String, CaseIterable {
    case OpenComments = "OPEN_COMMENTS"
    case OpenLink = "OPEN_LINK"
    case ShareComments = "SHARE_COMMENTS"
    case ShareLink = "SHARE_LINK"
    case DefaultTap = "com.apple.UNNotificationDefaultActionIdentifier" // UNNotificationDefaultActionIdentifier

    var title: String {
        switch self {
        case .OpenComments:
            return "Open Comments"
        case .OpenLink:
            return "Open Link"
        case .ShareComments:
            return "Share Comments"
        case .ShareLink:
            return "Share Link"
        case .DefaultTap:
            return "Default Tap"
        }
    }

    var action: UNNotificationAction {
        return UNNotificationAction(identifier: self.rawValue, title: self.title, options: [.foreground])
    }
}
