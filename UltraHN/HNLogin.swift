//
//  HNLogin.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftSoup

public protocol HNLoginDelegate {
    func didLogin(user: HNUser, cookie: HTTPCookie)
}

public class HNLogin {
    public let LoggedInNotificationName = Notification.Name(rawValue: "UltraHN.LoggedIn")
    public let LoggedOutNotificationName = Notification.Name(rawValue: "UltraHN.LoggedOut")

    private var observers: [HNLoginDelegate] = []

    public func addObserver(_ observer: HNLoginDelegate) {
        self.observers.append(observer)
    }

    public enum HNLoginError: Error {
        case badCredentials
        case serverUnreachable
        case unknown

        var description: String {
            switch self {
            case .badCredentials:
                return "Invalid username or password"
            case .serverUnreachable:
                return "Hacker News is unreachable"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }

    public static let shared = HNLogin()

    public var cookie: HTTPCookie? {
        get {
            let cookieArray = HTTPCookieStorage.shared.cookies(for: URL(string: "https://news.ycombinator.com/")!)
            return cookieArray?.first(where: { $0.name == "user" })
        }
    }

    public func Login(_ username: String, _ password: String) -> Promise<HNUser?> {
        let url = "https://news.ycombinator.com/login"

        let params: Parameters = ["acct": username, "pw": password, "goto": "user?id=" + username]

        return Alamofire.request(url, method: .post, parameters: params,
                                 encoding: URLEncoding.httpBody).responseString().then { (resp) -> Promise<HNUser?> in

            let document: Document = try SwiftSoup.parse(resp.string)

            if try document.select("#logout").first() != nil {
                if let cookie = self.cookie, let parsedUser = try? HTMLHNUser(userPage: document) {
                    for observer in self.observers {
                        observer.didLogin(user: parsedUser, cookie: cookie)
                    }

                    NotificationCenter.default.post(Notification(name: self.LoggedInNotificationName,
                                                                 object: parsedUser,
                                                                 userInfo: nil))

                    return Promise.value(parsedUser)
                } else {
                    print("No cookie found or page was unparseable, returning unknown error")
                    return Promise(error: HNLoginError.unknown)
                }
            } else if resp.response.response?.statusCode != 200 {
                // HN returns a 200 even if credentials are bad. So if we get any status other than 200 or 302,
                // it's probably a server issue
                return Promise(error: HNLoginError.serverUnreachable)
            }

            // Anything other than a 200 or 302 is bad news, lets try to deduce the error
            // Check document for the following:
            // "Bad login.", "Unknown or expired link."

            if let documentText = try document.body()?.text(), documentText.hasPrefix("Bad login.") {
                return Promise(error: HNLoginError.badCredentials)
            }

            print("UltraHN: Response doesn't match any style of known login response, returning unknown error!")
            return Promise(error: HNLoginError.unknown)
        }
    }

    /// Logout will delete the locally stored cookie and reset HNLogin state to new.
    public func Logout() {
        guard let cookie = self.cookie else {
            print("UltraHN: Refusing to logout as there is no user logged in!")
            return
        }

        HTTPCookieStorage.shared.deleteCookie(cookie)

        NotificationCenter.default.post(Notification(name: self.LoggedOutNotificationName,
                                                     object: nil, userInfo: nil))
    }

    /// Logout will delete the locally stored cookie and reset HNLogin state to new.
    /// If authString is provided, a logout request will also be sent to Hacker News.
    /// Setting authString also has the effect of logging out all active sessions, even on other devices.
    public func Logout(_ authString: String) -> Promise<(string: String, response: PMKAlamofireDataResponse)> {
        self.Logout()

        return Alamofire.request("https://news.ycombinator.com/logout",
                                 parameters: ["auth": authString]).responseString()
    }

}
