//
//  URLComponents+QueryDictionary.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/30/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension URLComponents {
    var queryItemsDictionary: [String: String]{
        set (queryItemsDictionary) {
            self.queryItems = queryItemsDictionary.map {
                URLQueryItem(name: $0, value: $1)
            }
        }
        get {
            var params = [String: String]()
            return queryItems?.reduce([:], { (_, item) -> [String: String] in
                params[item.name] = item.value
                return params
            }) ?? [:]
        }
    }
}
