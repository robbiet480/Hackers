//
//  HNSource.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit

public protocol HNDataSource {
    func GetPage(_ pageName: HNScraper.Page, pageNumber: Int) -> Promise<[HNItem]?>
    func GetItem(_ itemID: Int) -> Promise<HNItem?>
    func GetUser(_ username: String) -> Promise<HNUser?>

    var SupportedPages: [HNScraper.Page] { get }
}
