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
            handler(.noData)
            return
        }

        _ = HNUpdateManager.shared.loadPostsForType(.news).done { _ in
            let allPosts = Realm.live().objects(PostModel.self).filter("NotifiedAt == nil AND Points >= \(UserDefaults.standard.minimumPointsForNotification)")
            if isLocalNotificationEnabled {
                self.sendLocalPush(for: allPosts)

                handler(allPosts.count > 0 ? .newData : .noData)
            }
        }
    }

    private func sendLocalPush(for notifications: Results<PostModel>) {
        let center = UNUserNotificationCenter.current()
        notifications.forEach { post in
            let content = UNMutableNotificationContent()
            content.title = post.Title
            content.body = post.LinkURL.host!.replacingOccurrences(of: "www.", with: "")
            content.subtitle = post.Points.description + " points, posted by " + post.Username + " " + post.TimeCreatedString
            content.categoryIdentifier = "POST"
            content.userInfo = ["POST_ID": post.ID]

            getAttachmentForPost(post, handler: { (attachment) in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }

                let request = UNNotificationRequest(
                    identifier: post.ID.description,
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                )
                center.add(request)
            })
        }
    }

    func getAttachmentForPost(_ post: PostModel, handler: @escaping (UNNotificationAttachment?) -> Void) {
        post.Thumbnail(true) { (image) in
            if image != nil {
                let options = [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]
                do {
                    let attachment = try UNNotificationAttachment.init(identifier: post.ID.description, url: post.ThumbnailFileURL, options: options as [NSObject: AnyObject])
                    handler(attachment)
                } catch let attachmentError {
                    print("Error when building attachment", post.URLString, post.ID, post.ThumbnailFileURL, attachmentError)
                    handler(nil)
                }
            }
        }
    }

}
