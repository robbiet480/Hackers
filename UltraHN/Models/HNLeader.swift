//
//  HNLeader.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

public class HNLeader: NSObject {
    public var Rank: Int = 0
    public var Username: String = ""
    public var Karma: Int?

    public init(rank: Int, username: String, karma: Int?) {
        super.init()

        self.Rank = rank
        self.Username = username
        self.Karma = karma
    }

    override public var description: String {
        var str = "\(self.Username) is ranked #\(self.Rank.description) on the leaderboard with "

        if let karma = self.Karma {
            str += "\(karma) karma"
        } else {
            str += "an unknown amount of karma"
        }

        return str
    }
}