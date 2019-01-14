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
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        setAppTheme()
        UIFont.overrideInitialize()
        UNUserNotificationCenter.current().delegate = self

        // Obviously fake credentials but it works!
        FirebaseApp.configure(options: FirebaseOptions(googleAppID: "1:123456789112:ios:00a0aa1a00aa0000",
                                                       gcmSenderID: "123456789101"))


        KingfisherManager.shared.cache.pathExtension = "png"
        KingfisherManager.shared.defaultOptions = [.cacheSerializer(FormatIndicatedCacheSerializer.png),
                                                   .keepCurrentImageWhileLoading]

        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()

        NotificationCenter.default.addObserver(self, selector: #selector(brightnessChanged),
                                               name: UIScreen.brightnessDidChangeNotification, object: nil)

        print("Realm is stored at", Realm.live().configuration.fileURL!.description)
    }
    
    @objc private func setAppTheme() {
        AppThemeProvider.shared.currentTheme = UserDefaults.standard.brightnessCorrectTheme
    }

    @objc private func brightnessChanged(note: NSNotification) {
        // print("Brightness value didChange!", UIScreen.main.brightness)
        if let screen: UIScreen = note.object as? UIScreen {
            let threshold = UserDefaults.standard.brightnessLevelForThemeSwitch
            let currentTheme = AppThemeProvider.shared.currentTheme
            if screen.brightness > threshold && currentTheme == UserDefaults.standard.darkTheme {
                print("Go to light theme!")
                AppThemeProvider.shared.currentTheme = UserDefaults.standard.lightTheme
            } else if screen.brightness <= threshold && currentTheme == UserDefaults.standard.lightTheme {
                print("Go to dark theme!")
                AppThemeProvider.shared.currentTheme = UserDefaults.standard.darkTheme
            }
        }
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

        print("Handling didReceive!", response)

        let actionIdentifier = response.actionIdentifier
        let content = response.notification.request.content

        print("didReceive identifier", actionIdentifier)

        if actionIdentifier == UNNotificationDismissActionIdentifier {
            print("Dismiss action identifier didReceive!")
            completionHandler()
        } else {
            var userInfo: [AnyHashable: Any] = content.userInfo
            userInfo["action_identifier"] = actionIdentifier
            NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationOpenPost"),
                                            object: self, userInfo: userInfo)
            completionHandler()
        }
    }
}
