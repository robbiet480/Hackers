//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices

extension UserDefaults {
    public func openInBrowser(_ url: URL) -> ThemedSafariViewController? {
        let browserSetting = string(forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
        switch browserSetting {
        case "Google Chrome":
            if OpenInChromeController.sharedInstance.isChromeInstalled() {
                _ = OpenInChromeController.sharedInstance.openInChrome(url, callbackURL: nil)
            } else { // User uninstalled Chrome, fallback to Safari
                UserDefaults.standard.setOpenLinksIn("Safari")
                UIApplication.shared.open(url)
            }
            return nil
        case "Safari":
            UIApplication.shared.open(url)
            return nil
        case "In-app browser (Reader mode)":
            let config = SFSafariViewController.Configuration.init()
            config.barCollapsingEnabled = true
            config.entersReaderIfAvailable = true
            return ThemedSafariViewController(url: url, configuration: config)
        default:
            let config = SFSafariViewController.Configuration.init()
            config.barCollapsingEnabled = true
            return ThemedSafariViewController(url: url, configuration: config)
        }
    }

    public func setOpenLinksIn(_ browserName: String) {
        set(browserName, forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
    }

    public var lightTheme: AppTheme {
        set {
            set(newValue.description, forKey: UserDefaultsKeys.LightTheme.rawValue)
        }
        get {
            switch string(forKey: UserDefaultsKeys.LightTheme.rawValue) {
            case "Light":
                return AppTheme.light
            case "Dark":
                return AppTheme.dark
            case "Black":
                return AppTheme.black
            case "Original":
                return AppTheme.original
            default:
                return .light
            }
        }
    }

    public var darkTheme: AppTheme {
        set {
            set(newValue.description, forKey: UserDefaultsKeys.DarkTheme.rawValue)
        }
        get {
            switch string(forKey: UserDefaultsKeys.DarkTheme.rawValue) {
            case "Light":
                return AppTheme.light
            case "Dark":
                return AppTheme.dark
            case "Black":
                return AppTheme.black
            case "Original":
                return AppTheme.original
            default:
                return .dark
            }
        }
    }

    public var brightnessCorrectTheme: AppTheme {
        if !UserDefaults.standard.automaticThemeSwitch {
            return UserDefaults.standard.lightTheme
        }

        let brightnessCheck = UserDefaults.standard.brightnessLevelForThemeSwitch <= Float(UIScreen.main.brightness)
        return brightnessCheck ? UserDefaults.standard.lightTheme : UserDefaults.standard.darkTheme
    }

    public var brightnessLevelForThemeSwitch: Float {
        set {
            set(newValue, forKey: UserDefaultsKeys.BrightnessLevelForThemeSwitch.rawValue)
        }
        get {
            return float(forKey: UserDefaultsKeys.BrightnessLevelForThemeSwitch.rawValue)
        }
    }

    public var automaticThemeSwitch: Bool {
        set {
            set(newValue, forKey: UserDefaultsKeys.AutomaticThemeSwitch.rawValue)
            AppThemeProvider.shared.currentTheme = UserDefaults.standard.brightnessCorrectTheme
        }
        get {
            return bool(forKey: UserDefaultsKeys.AutomaticThemeSwitch.rawValue)
        }
    }

    public var minimumPointsForNotification: Int {
        set {
            set(newValue, forKey: UserDefaultsKeys.NotificationPointsThreshold.rawValue)
        }
        get {
            return integer(forKey: UserDefaultsKeys.NotificationPointsThreshold.rawValue)
        }
    }

    public var animateUpdates: Bool {
        set {
            set(newValue, forKey: UserDefaultsKeys.AnimateUpdates.rawValue)
        }
        get {
            return bool(forKey: UserDefaultsKeys.AnimateUpdates.rawValue)
        }
    }
}

enum UserDefaultsKeys: String {
    case DarkTheme
    case LightTheme
    case BrightnessLevelForThemeSwitch
    case AutomaticThemeSwitch
    case OpenInBrowser
    case NotificationPointsThreshold
    case AnimateUpdates
}
