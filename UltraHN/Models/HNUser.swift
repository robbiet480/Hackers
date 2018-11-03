//
//  HNUser.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

public class HNUser: NSObject, Codable {
    public var Username: String = "Unknown"
    public var Karma: Int = 0
    public var CreatedAt: Date?
    public var About: String?

    // Algolia fields
    public var CommentCount: Int?
    public var Average: Double?
    public var Delay: Double?
    public var SubmittedIDs: [Int]?
    public var SubmissionCount: Int?
    public var UpdatedAt: Date?

    // HTML fields
    public var IsNew: Bool = false
    public var TopColor: String?

    // HTML fields only visible to those that have completed YC
    public var IsYC: Bool = false
    public var Name: String?
    public var Bio: String?

    public override init() {
        super.init()
    }

    public init(username: String) {
        self.Username = username
    }

    public init(about: String?, average: Double?, commentCount: Int?, createdAt: Date?, delay: Double?, isNew: Bool,
                isYC: Bool, karma: Int, submissionCount: Int?, updatedAt: Date?, username: String) {
        self.About = about
        self.Average = average
        self.CommentCount = commentCount
        self.CreatedAt = createdAt
        self.Delay = delay
        self.IsNew = isNew
        self.IsYC = isYC
        self.Karma = karma
        self.SubmissionCount = submissionCount
        self.UpdatedAt = updatedAt
        self.Username = username
    }

    public init(username: String, karma: Int, createdAt: Date, about: String? = nil, isNew: Bool = false) {
        self.Username = username
        self.CreatedAt = createdAt
        self.Karma = karma
        self.About = about
        self.IsNew = isNew
    }

    override public var description: String {
        return "HNUser: \(self.Username), karma: \(self.Karma)"
    }

    var Color: UIColor? {
        if self.IsYC {
            return UIColor(rgb: 0xCD6E00)
        }
        if self.IsNew {
            return UIColor(rgb: 0x3C963C)
        }

        return nil
    }
}
