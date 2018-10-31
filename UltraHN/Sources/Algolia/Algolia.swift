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

    public init() { }

    public func GetPage(_ pageName: HNScraper.Page, pageNumber: Int = 1) -> Promise<[HNItem]?> {
        guard let url = pageName.algoliaQueryURL else { return Promise.value([HNItem]()) }

        return firstly {
                Alamofire.request(url).responseDecodable(AlgoliaSearchResult.self, decoder: ISO8601FullJSONDecoder())
            }.then { (resp) -> Promise<[HNItem]?> in
                let mapped: [HNItem] = resp.hits.map { $0.hnItem }

                return Promise.value(mapped)
            }
    }

    public func GetItem(_ itemID: Int) -> Promise<HNItem?> {
        let itemURL = self.baseURL + "items/" + itemID.description
        return Alamofire.request(itemURL).responseDecodable(AlgoliaHNItem.self,
                                                            decoder: ISO8601FullJSONDecoder()).map { $0 }
    }

    public func GetUser(_ username: String) -> Promise<HNUser?> {
        let userURL = self.baseURL + "users/" + username
        return Alamofire.request(userURL).responseDecodable(AlgoliaHNUser.self,
                                                            decoder: ISO8601FullJSONDecoder()).map { $0 as HNUser? }
    }

    public var SupportedPages: [HNScraper.Page] {
        return [.Home, .New, .ShowHN, .AskHN, .Jobs, .Over(points: 0), .ForDate(date: nil),
                .CommentsForUsername(username: ""), .SubmissionsForUsername(username: "")]
    }
}

fileprivate extension HNScraper.Page {
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
