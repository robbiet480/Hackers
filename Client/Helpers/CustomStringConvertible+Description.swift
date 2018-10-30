//
//  CustomStringConvertible+Description.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension CustomStringConvertible {
    var description: String {
        var description: String = "\(type(of: self))("

        let selfMirror = Mirror(reflecting: self)

        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "\(propertyName): \(child.value), "
            }
        }

        description += "<\(Unmanaged.passUnretained(self as AnyObject).toOpaque())>)"

        return description
    }
}
