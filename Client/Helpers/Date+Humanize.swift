//
//  Date+Humanize.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/1/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension Date {
    ///
    /// Provides a humanised date. For instance: 1 minute, 1 week ago, 3 months ago
    ///
    /// - Parameters:
    //      - numericDates: Set it to true to get "1 year ago", "1 month ago" or false if you prefer "Last year", "Last month"
    ///
    func timeAgo(numericDates:Bool) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = self < now ? self : now
        let latest =  self > now ? self : now

        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfMonth, .month, .year, .second]
        let components: DateComponents = calendar.dateComponents(unitFlags, from: earliest, to: latest)
        //print("")
        //print(components)
        if let year = components.year {
            if (year >= 2) {
                return "\(year)y"
            } else if (year >= 1) {
                return numericDates ?  "1y" : "Last year"
            }
        }
        if let month = components.month {
            if (month >= 2) {
                return "\(month)m"
            } else if (month >= 1) {
                return numericDates ? "1mo" : "Last month"
            }
        }
        if let weekOfMonth = components.weekOfMonth {
            if (weekOfMonth >= 2) {
                return "\(weekOfMonth)w"
            } else if (weekOfMonth >= 1) {
                return numericDates ? "1w" : "Last week"
            }
        }
        if let day = components.day {
            if (day >= 2) {
                return "\(day)d"
            } else if (day >= 1) {
                return numericDates ? "1d" : "Yesterday"
            }
        }
        if let hour = components.hour {
            if (hour >= 2) {
                return "\(hour)h"
            } else if (hour >= 1) {
                return numericDates ? "1h" : "An hour ago"
            }
        }
        if let minute = components.minute {
            if (minute >= 2) {
                return "\(minute)m"
            } else if (minute >= 1) {
                return numericDates ? "1m" : "A minute ago"
            }
        }
        if let second = components.second {
            if (second >= 3) {
                return "\(second)s"
            }
        }
        return "now"
    }
}
