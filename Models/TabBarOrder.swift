//
//  TabBarOrder.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/22/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import HNScraper

class TabBarOrder: Object {
    @objc dynamic var pageName: String = HNScraper.PostListPageName.news.tabTitle
    @objc dynamic var index: Int = 0

    convenience init(_ index: Int, _ pageName: String) {
        self.init()

        self.index = index
        self.pageName = pageName
    }
}
