//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices
import HNScraper

extension UserDefaults {
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

    public var shouldSwitchTheme: Bool {
        if !UserDefaults.standard.automaticThemeSwitch {
            return false
        }

        let setLevel = UserDefaults.standard.brightnessLevelForThemeSwitch

        return setLevel <= UIScreen.main.brightness
    }

    public var brightnessCorrectTheme: AppTheme {
        if !UserDefaults.standard.automaticThemeSwitch {
            return UserDefaults.standard.lightTheme
        }

        return self.shouldSwitchTheme ? UserDefaults.standard.lightTheme : UserDefaults.standard.darkTheme
    }

    public var brightnessLevelForThemeSwitch: CGFloat {
        set {
            set(newValue, forKey: UserDefaultsKeys.BrightnessLevelForThemeSwitch.rawValue)
        }
        get {
            return CGFloat(float(forKey: UserDefaultsKeys.BrightnessLevelForThemeSwitch.rawValue))
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

    public var loggedInUser: HNUser? {
        set {
            if newValue == nil {
                removeObject(forKey: UserDefaultsKeys.LoggedInUser.rawValue)
                return
            }
            set(try? PropertyListEncoder().encode(newValue), forKey: UserDefaultsKeys.LoggedInUser.rawValue)
        }
        get {
            guard let storedObj = object(forKey: UserDefaultsKeys.LoggedInUser.rawValue) as? Data else { return nil }
            guard let user: HNUser = try? PropertyListDecoder().decode(HNUser.self, from: storedObj) else { return nil }
            return user
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
    case Username
    case Password
    case LoggedInUser
}
