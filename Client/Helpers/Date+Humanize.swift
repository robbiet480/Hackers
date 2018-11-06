//
//  Date+Humanize.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/1/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

// From https://gist.github.com/minorbug/468790060810e0d29545#gistcomment-2714133
extension Date {
    ///
    /// Provides a humanised date. For instance: 1 minute, 1 week ago, 3 months ago
    ///
    /// - Parameters:
    //      - short: Set it to true to get "1y", "1mo" or false if you prefer "Last year", "Last month"
    ///
    func timeAgo(short: Bool) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = self < now ? self : now
        let latest = self > now ? self : now

        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfMonth, .month, .year, .second]
        let components: DateComponents = calendar.dateComponents(unitFlags, from: earliest, to: latest)

        if let year = components.year {
            if (year >= 2) {
                return short ? "\(year)y" : "\(year) years ago"
            } else if (year >= 1) {
                return short ? "1y" : "Last year"
            }
        }
        if let month = components.month {
            if (month >= 2) {
                return short ? "\(month)mo" : "\(month) months ago"
            } else if (month >= 1) {
                return short ? "1mo" : "Last month"
            }
        }
        if let weekOfMonth = components.weekOfMonth {
            if (weekOfMonth >= 2) {
                return short ? "\(weekOfMonth)w" : "\(weekOfMonth) weeks ago"
            } else if (weekOfMonth >= 1) {
                return short ? "1w" : "Last week"
            }
        }
        if let day = components.day {
            if (day >= 2) {
                return short ? "\(day)d" : "\(day) days ago"
            } else if (day >= 1) {
                return short ? "1d" : "Yesterday"
            }
        }
        if let hour = components.hour {
            if (hour >= 2) {
                return short ? "\(hour)h" : "\(hour) hours ago"
            } else if (hour >= 1) {
                return short ? "1h" : "An hour ago"
            }
        }
        if let minute = components.minute {
            if (minute >= 2) {
                return short ? "\(minute)m" : "\(minute) minutes ago"
            } else if (minute >= 1) {
                return short ? "1m" : "A minute ago"
            }
        }
        if let second = components.second {
            if (second >= 2) {
                return short ? "\(second)s" : "\(second) seconds ago"
            }
        }
        return "now"
    }
}
