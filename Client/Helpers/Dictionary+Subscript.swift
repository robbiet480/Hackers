//
//  Dictionary+Subscript.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/1/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral {
    subscript<Index: RawRepresentable>(index: Index) -> Value? where Index.RawValue == String {
        get {
            return self[index.rawValue as! Key]
        }

        set {
            self[index.rawValue as! Key] = newValue
        }
    }
}
