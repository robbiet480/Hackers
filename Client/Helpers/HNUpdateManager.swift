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
    public static let shared: HNUpdateManager = HNUpdateManager()

    private var notificationToken: NotificationToken? = nil
    private var nextPageIdentifiers: [HNScraper.PostListPageName: String] = [:]

    private let results = Realm.live().objects(PostModel.self)

    init() {
        notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                return
            case .update(_, _, let insertions, _):
                // Query results have changed, so apply them to the UITableView
                if insertions.count > 0 {
                    print("Update happened with insertions", insertions)
                }
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
        print("LOADING ALL POSTS")
        // FIXME: add .ask and .jobs once the ID is fixed...

        let allPostTypes = [getPosts(.new),
                            getPosts(.news),
                            getPosts(.asks),
                            getPosts(.jobs)]

        return when(fulfilled: allPostTypes).map { Array($0.joined()) }.ensure {
            print("Done loading all posts!")
        }
    }

    func loadPostsForType(_ pType: HNScraper.PostListPageName) -> Promise<[PostModel]> {
        return getPosts(pType)
    }

    func loadMorePosts(_ pType: HNScraper.PostListPageName) -> Promise<[PostModel]> {
        guard let nextPageIdentifier = self.nextPageIdentifiers[pType] else {
            return Promise.init(error: NSError(domain: "com.weiranzhang.Hackers", code: 999, userInfo: nil))
        }

        self.nextPageIdentifiers[pType] = nil

        return getPosts(pType, nextPageIdentifier)
    }

    private func getPosts(_ pType: HNScraper.PostListPageName, _ pageIdentifier: String? = nil) -> Promise<[PostModel]> {
        //let bgq = DispatchQueue.global(qos: .background)

        var funcToRun = getPostsForTypePromise(pType)

        if let pi = pageIdentifier {
            funcToRun = getPostsForPagePromise(pType, pi)
        }

        return funcToRun.thenMap { post -> Promise<HNPost> in
            self.loadComments(post)
        }.mapValues { post -> PostModel in
            return PostModel(post)
        }.thenMap { post -> Promise<PostModel> in
            return self.getPostThumbnail(post)
        }.then { posts -> Promise<[PostModel]> in
            let realm = Realm.live()

            try! realm.write {
                realm.add(posts, update: true)
            }

            return Promise.value(posts)
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
                    self.nextPageIdentifiers[pType] = npi
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
                    self.nextPageIdentifiers[pType] = npi
                }

                seal.fulfill(posts)
            })
        }
    }

    private func getPostThumbnail(_ post: PostModel) -> Promise<PostModel> {
        return Promise { seal in
            post.ThumbnailURL { thumbURL in
                if let url = thumbURL {
                    post.ThumbnailURLString = url.absoluteString
                    seal.fulfill(post)
                }
            }
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
