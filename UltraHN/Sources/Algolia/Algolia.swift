//
//  Algolia.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

public class AlgoliaDataSource: HNDataSource {
    public let baseURL = "https://hn.algolia.com/api/v1/"

    public func GetPage(_ pageName: NewHNScraper.Page) -> Promise<[NewHNItem]?> {
        guard let url = pageName.algoliaQueryURL else { return Promise.value([NewHNItem]()) }

        return firstly {
                Alamofire.request(url).responseAlgoliaSearchResult()
            }.then { (resp) -> Promise<[NewHNItem]?> in
                let mapped: [NewHNItem] = resp.item.hits.map { $0.hnItem }

                return Promise.value(mapped)
            }
    }

    public func GetItem(_ itemID: Int) -> Promise<NewHNItem?> {
        let algoliaURL = self.baseURL + "items/" + itemID.description
        return Alamofire.request(algoliaURL).responseNewHNItem().then { resp -> Promise<NewHNItem?> in
            _ = resp.item.collectChildren()

            return Promise.value(resp.item)
        }
    }

    public func GetUser(_ username: String) -> Promise<NewHNUser?> {
        let pageURL = self.baseURL + "users/" + username

        return Alamofire.request(pageURL).responseAlgoliaHNUser().then({ (arg0) -> Promise<NewHNUser?> in
            return Promise.value(arg0.user as NewHNUser)
        })
    }

    func GetComments(_ itemID: Int) -> Promise<[NewHNComment]?> {
        return self.GetItem(itemID).then { item -> Promise<[NewHNComment]?> in
            guard let children = item?.Children else { return Promise.value([NewHNComment]()) }

            guard let castedChildren = children as? [NewHNComment] else { return Promise.value([NewHNComment]()) }

            return Promise.value(castedChildren)
        }
    }

    public var SupportedPages: [NewHNScraper.Page] {
        return [.Home, .New, .ShowHN, .AskHN, .Jobs, .Over(points: 0), .ForDate(date: nil), .CommentsForUsername(username: ""), .SubmissionsForUsername(username: "")]
    }
}

fileprivate extension NewHNScraper.Page {
    var algoliaQueryURL: URL? {
        var path = "search"
        switch self {
        case .Home:
            path = "search?tags=front_page"
        case .New:
            path = "search_by_date?tags=story"
        case .ShowHN:
            path = "search?tags=show_hn"
        case .AskHN:
            path = "search?tags=ask_hn"
        case .Jobs:
            path = "search?tags=job"
        case .Over(let points):
            path = "search?numericFilters=points>" + points.description
        case .ForDate(let givenDate):
            let date = givenDate != nil ? givenDate! : Date()
            path = "search_by_date?tags=comment&numericFilters=created_at_i>" + date.timeIntervalSince1970.description
        case .SubmissionsForUsername(let username):
            path = "search?tags=story,author_"+username
        case .CommentsForUsername(let username):
            path = "search?tags=comment,author_"+username
        default:
            return nil
        }

        return URL(string: path, relativeTo: URL(string: "https://hn.algolia.com/api/v1/")!)
    }
}
