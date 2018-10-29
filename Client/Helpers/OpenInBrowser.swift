//
//  OpenInBrowser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/24/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SafariServices

public class OpenInBrowser {
    public enum OpenableBrowser: Int, CaseIterable {
        case SFSafariViewController = 1
        case SFSafariViewControllerReader = 2
        case Safari = 3
        case GoogleChrome = 4
        case MozillaFirefox = 5

        public var description: String {
            switch self {
            case .SFSafariViewController:
                return "In-app browser"
            case .SFSafariViewControllerReader:
                return "In-app browser (Reader mode)"
            case .Safari:
                return "Safari"
            case .GoogleChrome:
                return "Google Chrome"
            case .MozillaFirefox:
                return "Mozilla Firefox"
            }
        }
    }

    public static let shared = OpenInBrowser()

    public var fallbackBrowser: OpenableBrowser = .Safari

    public var preferenceStorageKey: String = "openInBrowser"

    /// Get the users preferred open in browser
    public var browser: OpenableBrowser {
        get {
            let stored = UserDefaults.standard.integer(forKey: self.preferenceStorageKey)

            guard let browser = OpenableBrowser(rawValue: stored) else { return self.fallbackBrowser }

            return browser
        }
        set {
            return UserDefaults.standard.set(newValue.rawValue, forKey: self.preferenceStorageKey)
        }
    }

    /// Determine what browsers are openable
    public var installedBrowsers: [OpenableBrowser] {
        var installedBrowsers: [OpenableBrowser] = [.SFSafariViewController, .SFSafariViewControllerReader, .Safari]

        if OpenInChromeController.shared.isChromeInstalled() {
            installedBrowsers.append(.GoogleChrome)
        }

        if OpenInFirefoxController.shared.isFirefoxInstalled() {
            installedBrowsers.append(.MozillaFirefox)
        }

        return installedBrowsers
    }

    /// Open the given URL in a browser
    public func openURL(_ url: URL,
                        _ browser: OpenableBrowser = OpenInBrowser.shared.browser) -> ThemedSafariViewController? {
        switch self.browser {
        case .SFSafariViewController:
            return ThemedSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
        case .SFSafariViewControllerReader:
            return ThemedSafariViewController(url: url, configuration: SFSafariViewController.Configuration(true))
        case .Safari:
            UIApplication.shared.open(url)
            return nil
        case .GoogleChrome:
            guard OpenInChromeController.shared.isChromeInstalled() else { return self.openURL(url, .Safari)  }

            OpenInChromeController.shared.openInChrome(url)

            return nil
        case .MozillaFirefox:
            guard OpenInFirefoxController.shared.isFirefoxInstalled() else { return self.openURL(url, .Safari)  }

            OpenInFirefoxController.shared.openInFirefox(url)

            return nil
        }

    }
}

public extension SFSafariViewController.Configuration {
    convenience init(_ readerMode: Bool = false) {
        self.init()

        self.entersReaderIfAvailable = readerMode
        self.barCollapsingEnabled = true
    }
}
