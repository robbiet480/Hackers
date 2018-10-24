//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Kingfisher
import RealmSwift
import UserNotifications
import HNScraper
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        UIFont.overrideInitialize()
        UNUserNotificationCenter.current().delegate = self

        FirebaseApp.configure(options: FirebaseOptions(googleAppID: "1:123456789112:ios:00a0aa1a00aa0000",
                                                       gcmSenderID: "123456789101"))

        KingfisherManager.shared.cache.pathExtension = "png"
        KingfisherManager.shared.defaultOptions = [.cacheSerializer(FormatIndicatedCacheSerializer.png),
                                                   .keepCurrentImageWhileLoading]

        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()
        setAppTheme()

        //HNFirebaseClient.shared.getStoriesForPage(.news)

        HNParseConfig.shared.jsonConfigURL = "http://192.168.7.25:8000/hn.json"

        HNParseConfig.shared.forceRedownload { (error) in
            if let error = error {
                print("Error while downloading hn.json", error)
            } else {
                print("Downloaded hn.json")
            }
        }

        HNScraper.shared.parseDead = true

        //_ = HNUpdateManager.shared.loadAllPosts()

        NotificationCenter.default.addObserver(self, selector: #selector(setAppTheme),
                                               name: UIScreen.brightnessDidChangeNotification, object: nil)

        print("Realm is stored at", Realm.live().configuration.fileURL!.description)
    }
    
    @objc private func setAppTheme(_ notification: Notification? = nil) {
        AppThemeProvider.shared.currentTheme = UserDefaults.standard.brightnessCorrectTheme
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        print("Handling didReceive!")

        let actionIdentifier = response.actionIdentifier
        let content = response.notification.request.content

        print("didReceive identifier", actionIdentifier)

        switch actionIdentifier {
        case UNNotificationDismissActionIdentifier: // Notification was dismissed by user
            // Do something
            print("Dismiss action identifier didReceive!")
            completionHandler()
        case UNNotificationDefaultActionIdentifier: // App was opened from notification
            // Do something
            print("Default action identifier didReceive!")
            if let postID = content.userInfo["POST_ID"] as? Int {
                print("Open post ID", postID)

                let userInfo = ["POST_ID":postID]
                NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationOpenPost"),
                                                object: self, userInfo: userInfo)

            }
            completionHandler()
//        case "com.usernotificationstutorial.delete":
//            // Delete message
//            completionHandler()
        default:
            print("Some other action identifier received", actionIdentifier)
            completionHandler()
        }
    }
}
