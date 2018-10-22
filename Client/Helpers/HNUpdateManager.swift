//
//  HNUpdateManager.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/22/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import PromiseKit
import HNScraper

class HNUpdateManager {
    static let shared = HNUpdateManager()

    private var notificationToken: NotificationToken? = nil
    private var nextPageIdentifiers: [Int: String] = [:]

    init() {
        _ = self.loadAllPosts()

        let realm = Realm.live()
        let results = realm.objects(PostModel.self)

        notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                print("Initial")
            case .update(_, _, let insertions, _):
                // Query results have changed, so apply them to the UITableView
                print("Update happened with insertions", insertions)
                // TODO: With insertions, send notifications
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("Error in Realm notification \(error)")
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

    func loadAllPosts() -> Promise<[PostModel]> {
        // FIXME: add .ask and .jobs once the ID is fixed...
        return firstly {
            return when(fulfilled: [getPostsForType(.new), getPostsForType(.news), getPostsForType(.asks), getPostsForType(.jobs)]).map { Array($0.joined()) }
        }.then { posts -> Promise<[PostModel]> in
            print("All done with storing posts and thumbnails!", posts)

            let realm = Realm.live()

            try! realm.write {
                realm.add(posts, update: true)
            }

            return Promise.value(posts)
        }
    }

    func loadPostsForType(_ pType: HNScraper.PostListPageName) -> Promise<[PostModel]> {
        return firstly {
            getPostsForType(pType)
        }.then { posts -> Promise<[PostModel]> in
            print("All done with storing single type of posts and thumbnails!", posts)

            let realm = Realm.live()

            try! realm.write {
                realm.add(posts, update: true)
            }

            return Promise.value(posts)
        }
    }

    func loadMorePosts(_ pType: HNScraper.PostListPageName) -> Promise<[PostModel]> {
        guard let nextPageIdentifier = self.nextPageIdentifiers[pType.hashValue] else {
            return Promise.init(error: NSError(domain: "com.weiranzhang.Hackers", code: 999, userInfo: nil))
        }

        self.nextPageIdentifiers[pType.hashValue] = nil

        return firstly {
            getPostsForPage(pType, nextPageIdentifier)
        }.then { posts -> Promise<[PostModel]> in
            self.nextPageIdentifiers[pType.hashValue] = nextPageIdentifier
            print("All done with storing new page of posts and thumbnails!", posts)

            let realm = Realm.live()

            try! realm.write {
                realm.add(posts, update: true)
            }

            return Promise.value(posts)
        }
    }

    private func getPostsForType(_ pType: HNScraper.PostListPageName) -> Promise<[PostModel]> {
        return firstly {
            getPostsForTypePromise(pType)
        }.thenMap { post in
            self.loadComments(post)
        }.mapValues { post in
            return PostModel(post)
        }.thenMap { post in
            return self.getPostThumbnail(post)
        }
    }

    private func getPostsForPage(_ pType: HNScraper.PostListPageName, _ pageIdentifier: String) -> Promise<[PostModel]> {
        return firstly {
            getPostsForPagePromise(pType, pageIdentifier)
        }.thenMap { post in
            self.loadComments(post)
        }.mapValues { post in
            return PostModel(post)
        }.thenMap { post in
            return self.getPostThumbnail(post)
        }
    }

    private func getPostsForTypePromise(_ pType: HNScraper.PostListPageName) -> Promise<[HNPost]> {
        return Promise { seal in
            HNScraper.shared.getPostsList(page: pType, completion: { (posts, nextPageIdentifier, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                if let npi = nextPageIdentifier {
                    self.nextPageIdentifiers[pType.hashValue] = npi
                }
                seal.fulfill(posts)
            })
        }
    }

    private func getPostsForPagePromise(_ pType: HNScraper.PostListPageName, _ pageIdentifier: String) -> Promise<[HNPost]> {
        return Promise { seal in
            HNScraper.shared.getMoreItems(linkForMore: pageIdentifier, completionHandler: { (posts, nextPageIdentifier, error) in
                if let error = error {
                    seal.reject(error)
                    return
                }
                
                if let npi = nextPageIdentifier {
                    self.nextPageIdentifiers[pType.hashValue] = npi
                }

                seal.fulfill(posts)
            })
        }
    }

    private func getPostThumbnail(_ post: PostModel) -> Promise<PostModel> {
        return Promise { seal in
            post.ThumbnailURL({ (thumbURL) in
                if let url = thumbURL {
                    post.ThumbnailURLString = url.absoluteString
                    seal.fulfill(post)
                }
            })
        }
    }

    func loadComments(_ post: HNPost) -> Promise<HNPost> {
        return Promise { seal in
            HNScraper.shared.getComments(ByPostId: post.id, completion: { (_, comments, error) in
                let mappedComments = comments.map { CommentModel($0, PostModel(post)) }

                let realm = Realm.live()
                try! realm.write {
                    realm.add(mappedComments, update: true)
                }

                seal.fulfill(post)
            })
        }
    }

}
