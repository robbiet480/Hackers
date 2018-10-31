//
//  HNComment.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/28/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

public class HNComment: HNItem {
    // FadeLevel equates to number of downvotes received after the comment already had 0 points.
    // The higher the level the more downvotes you have.
    // There are 10 levels in all
    var FadeLevel: Int = 0

    override public var description: String {
        return "HNComment: author: \(self.Author)"
    }

    // FadeColor is the text color you should use when displaying the comment to match Hacker News stylings.
    public var FadeColor: UIColor {
        switch self.FadeLevel {
            case 0:
                return UIColor(rgb: 0x000000)
            case 1:
                return UIColor(rgb: 0x5A5A5A)
            case 2:
                return UIColor(rgb: 0x737373)
            case 3:
                return UIColor(rgb: 0x828282)
            case 4:
                return UIColor(rgb: 0x888888)
            case 5:
                return UIColor(rgb: 0x9C9C9C)
            case 6:
                return UIColor(rgb: 0xAEAEAE)
            case 7:
                return UIColor(rgb: 0xBEBEBE)
            case 8:
                return UIColor(rgb: 0xCECECE)
            default: // We use level 9 as the default since that color is basically unreadable on light backgrounds.
                return UIColor(rgb: 0xDDDDDD)
        }
    }
}
