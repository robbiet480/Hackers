//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import libHN
import Kingfisher
import RealmSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        HNManager.shared().startSession()
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()
        setAppTheme()
        UIFont.overrideInitialize()
        UNUserNotificationCenter.current().delegate = self

        KingfisherManager.shared.cache.pathExtension = "png"
        KingfisherManager.shared.defaultOptions = [.cacheSerializer(FormatIndicatedCacheSerializer.png), .keepCurrentImageWhileLoading]
    }
    
    private func setAppTheme() {
        AppThemeProvider.shared.currentTheme = UserDefaults.standard.enabledTheme
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Notifications().fetch(application: application, handler: completionHandler)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .badge, .sound])
        return
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        if let postID = response.notification.request.content.userInfo["POST_ID"] as? String {
            print("Open post ID", postID)

            let userInfo = ["POST_ID":postID]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationOpenPost"), object: self, userInfo: userInfo)

            //                    self.window!.rootViewController = UINavigationController(rootViewController: YourController(yourMember: something))
        }

        completionHandler()
    }
}
