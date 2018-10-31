//
//  HTMLHNUser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftSoup

public class HTMLHNUser: HNUser {
    public enum UserPageFields: String, CaseIterable {
        case About = "about"
        // case Created = "created"
        case Karma = "karma"
        case User = "user"

        // These fields only appears if you are logged in as someone that has completed YC
        case Name = "name"
        case Bio = "bio"

        // These fields are form values
        case TopColor = "topcolor"
    }

    /// Expects a .hnuser to be provided
    public init(hnUserElement: Element) {
        super.init()

        self.parseUsernameElement(hnUserElement: hnUserElement)
    }

    public init(documentWithHeader: Document) throws {
        super.init()

        do {
            let userText = try documentWithHeader.select(".pagetop").last()?.text()
            let splitUserText = userText?.split(separator: Character.space)

            if let username = splitUserText?.first?.description {
                self.Username = username
            }

            if var karma = splitUserText?[1].description {
                karma.removeFirst()
                karma.removeLast()
                if let karmaInt = Int(string: karma) {
                    self.Karma = karmaInt
                }
            }
        } catch let error as NSError {
            throw error
        }
    }

    public init(userPage: Document) throws {
        super.init()

        do {
            let isEditing = try userPage.select("form.profileform").first() != nil

            let rows = try userPage.select("td[valign]")

            for row in rows {
                let next = try row.nextElementSibling()!

                var label = try row.text()
                label.removeLast()

                let value = try next.text()

                if let enumLabel = HTMLHNUser.UserPageFields(rawValue: label) {
                    switch enumLabel {
                    case .User:
                        self.parseUsernameElement(hnUserElement: try next.select(".hnuser").first()!)
                    case .Karma:
                        if let karmaInt = Int(string: value) {
                            self.Karma = karmaInt
                        }
                    case .About:
                        if isEditing {
                            self.About = try next.select("textarea[name=about]").val()
                        } else {
                            self.About = value
                        }
                    case .Bio:
                        self.Bio = value
                    case .Name:
                        if isEditing {
                            self.Name = try next.select("input[name=fullname]").val()
                        } else {
                            self.Name = value
                        }
                    case .TopColor:
                        self.TopColor = try next.select("input[name=topc]").val()
                    }
                }
            }
        } catch let error as NSError {
            throw error
        }
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    private static func dateFromFormat(date: String, dateFormat: String = "yyyy-MM-dd") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        let date = dateFormatter.date(from: date)
        return date ?? Date()
    }

    public func parseUsernameElement(hnUserElement: Element) {
        if let username = try? hnUserElement.text() {
            self.Username = username
        }

        if let fontColor = try? hnUserElement.select("font").attr("color") {
            self.IsYC = (fontColor == "#cd6e00")
            self.IsNew = (fontColor == "#3c963c")
        }

        if let timestampStr = try? hnUserElement.parent()?.attr("timestamp"),
            let timestamp = timestampStr,
            let interval = TimeInterval(string: timestamp) {

            print("Got timestamp")
            self.CreatedAt = Date(seconds: interval)
        }
    }
}
