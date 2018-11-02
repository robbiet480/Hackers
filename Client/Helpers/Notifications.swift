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

    private static let defaults = UserDefaults.standard

    private static let notificationKey = "com.weiranzhang.Hackers.notifications-enabled"
    static var isLocalNotificationEnabled: Bool {
        get { return defaults.bool(forKey: notificationKey) }
        set { return defaults.set(newValue, forKey: notificationKey)}
    }

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
        var options: UNAuthorizationOptions = []

        if isLocalNotificationEnabled {
            options = [.alert, .badge, .sound]
        }

        if !options.isEmpty {
            UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (granted, _) in
                permissionHandler?(granted)
            })

            // Define the custom actions.
            let openCommentsAction = UNNotificationAction(identifier: "OPEN_COMMENTS",
                                                    title: "Open Comments",
                                                    options: [.foreground])
            let openLinkAction = UNNotificationAction(identifier: "OPEN_LINK",
                                                      title: "Open Link",
                                                      options: [.foreground])
            let shareHNLinkAction = UNNotificationAction(identifier: "SHARE_HN_LINK",
                                                         title: "Share Hacker News Link",
                                                         options: [.foreground])
            let shareLinkAction = UNNotificationAction(identifier: "SHARE_LINK",
                                                       title: "Share Link",
                                                       options: [.foreground])
            // Define the notification type
            let storyNotificationCategory =
                UNNotificationCategory(identifier: "POST",
                                       actions: [openCommentsAction, openLinkAction, shareHNLinkAction, shareLinkAction],
                                       intentIdentifiers: [],
                                       hiddenPreviewsBodyPlaceholder: "",
                                       options: .customDismissAction)
            // Register the notification type.
            UNUserNotificationCenter.current().setNotificationCategories([storyNotificationCategory])

            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        } else {
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }
    }

    func fetch(application: UIApplication, handler: @escaping (UIBackgroundFetchResult) -> Void) {
        let isLocalNotificationEnabled = Notifications.isLocalNotificationEnabled
        guard isLocalNotificationEnabled else {
            print("Notifications are disabled")
            handler(.noData)
            return
        }

        HNScraper.shared.GetPage(HNScraper.Page.Home).done { items in
            guard let items = items else { handler(.noData); return }
            var itemsMeetingCriteria: [HNPost] = []

            for item in items {
                if item.Score ?? 0 >= UserDefaults.standard.minimumPointsForNotification, let post = item as? HNPost {
                    itemsMeetingCriteria.append(post)
                }
            }

            print("Got", itemsMeetingCriteria.count, "possible notifies")

            let previousIDs = Realm.live().objects(ItemLog.self).filter("NotifiedAt != nil").map { $0.ID }

            print("Got", previousIDs.count, "previously stored IDs")

            let filtered = itemsMeetingCriteria.filter({ post -> Bool in
                return !previousIDs.contains(post.ID)
            })

            print("Got", filtered.count, "filtered notifies")

            self.sendLocalPush(for: filtered)

            handler(filtered.count > 0 ? .newData : .noData)

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
            if let link = post.Link {
                content.body = link.host!.replacingOccurrences(of: "www.", with: "")
            }
            content.subtitle = "Posted " + post.RelativeDate
            if let score = post.Score, let author = post.Author {
                content.subtitle = score.description + " points, posted by " + author.Username + " " + post.RelativeDate
            }
            if post.Rank > 0 {
                content.subtitle = "#" + String(post.Rank) + ", " + content.subtitle
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
        post.Thumbnail(true) { (image) in
            if image != nil {
                let options = [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]
                do {
                    let attachment = try UNNotificationAttachment.init(identifier: post.IDString, url: post.ThumbnailFileURL, options: options as [NSObject: AnyObject])
                    handler(attachment)
                } catch let attachmentError {
                    print("Error when building attachment", post.Link, post.IDString, post.ThumbnailFileURL, attachmentError)
                    handler(nil)
                }
            }
        }
    }

}
