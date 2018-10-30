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
    func GetPage(_ pageName: NewHNScraper.Page) -> Promise<[NewHNItem]?>
    func GetItem(_ itemID: Int) -> Promise<NewHNItem?>
    func GetUser(_ username: String) -> Promise<NewHNUser?>
    // func GetComments(_ itemID: Int) -> Promise<[NewHNComment]?>

    var SupportedPages: [NewHNScraper.Page] { get }
}
