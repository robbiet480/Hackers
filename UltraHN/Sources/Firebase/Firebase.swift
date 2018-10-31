//
//  Firebase.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/29/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit
import FirebaseDatabase
import CodableFirebase

public class FirebaseDataSource: HNDataSource {
    public static let shared: FirebaseDataSource = FirebaseDataSource()

    public static let dbRef: DatabaseReference = Database.database(url: "https://hacker-news.firebaseio.com").reference().child("v0")

    public init() { }

    public func GetPage(_ pageName: HNScraper.Page, pageNumber: Int = 1) -> Promise<[HNItem]?> {
        guard let path = pageName.firebasePath else { return Promise.value([HNItem]()) }

        return Promise { seal in
            FirebaseDataSource.dbRef.child(path).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let value = snapshot.value else { return seal.fulfill(nil) }

                do {
                    seal.fulfill(try FirebaseDecoder().decode([FirebaseHNItem].self, from: value))
                } catch let error {
                    seal.reject(error)
                }
            }, withCancel: { (error) in
                seal.reject(error)
            })
        }
    }

    public func GetItem(_ itemID: Int) -> Promise<HNItem?> {
        let itemRef = FirebaseDataSource.dbRef.child("item/" + itemID.description)

        return Promise {seal in
            itemRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let value = snapshot.value else { return seal.fulfill(nil) }

                do {
                    seal.fulfill(try FirebaseDecoder().decode(FirebaseHNItem.self, from: value))
                } catch let error {
                    seal.reject(error)
                }
            }) { (error) in
                seal.reject(error)
            }
        }
    }

    public func GetUser(_ username: String) -> Promise<HNUser?> {
        let itemRef = FirebaseDataSource.dbRef.child("user/"+username)

        return Promise {seal in
            itemRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let value = snapshot.value else { return seal.fulfill(nil) }

                do {
                    seal.fulfill(try FirebaseDecoder().decode(FirebaseHNUser.self, from: value))
                } catch let error {
                    seal.reject(error)
                }
            }) { (error) in
                seal.reject(error)
            }
        }
    }

    public var SupportedPages: [HNScraper.Page] {
        return [.Home, .New, .Jobs, .AskHN, .ShowHN, .Best, .SubmissionsForUsername(username: "")]
    }
}

extension HNScraper.Page {
    var firebasePath: String? {
        switch self {
        case .Home:
            return "topstories"
        case .New:
            return "newstories"
        case .Jobs:
            return "jobstories"
        case .AskHN:
            return "askstories"
        case .ShowHN, .ShowHNNew:
            return "showstories"
        case .Best:
            return "beststories"
        case .SubmissionsForUsername(let username):
            return "user/" + username
        default:
            return nil
        }
    }
}
