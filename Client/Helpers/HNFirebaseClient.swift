//
//  HNFirebaseClient.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/23/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import FirebaseDatabase
import HNScraper
import PromiseKit
import OpenGraph

public class HNFirebaseClient {
    public static let shared: HNFirebaseClient = HNFirebaseClient()

    public var dbRef: DatabaseReference = Database.database(url: "https://hacker-news.firebaseio.com").reference().child("v0")

    func getStoriesForPage(_ page: HNScraper.PostListPageName, limit: Int = 30) -> Promise<[PostModel]> {
        guard page.firebasePath != nil else { return Promise.value([PostModel]()) }

        return getItemIDsForPage(page, limit).then { self.getAndSaveStoriesForIDs($0) }
    }

    func getAndSaveStoriesForIDs(_ storyIDs: [Int]) -> Promise<[PostModel]> {
        return Promise.value(storyIDs).thenMap { postID -> Promise<HNItem?> in
            return self.getItemForID(postID)
        }.compactMapValues { (item: HNItem?) -> PostModel? in
            return item as? PostModel
        }.thenMap { (post: PostModel) -> Promise<PostModel> in
            guard let urlStr = post.URLString else { return Promise.value(post) }

            return self.getPostMetadata(urlStr).then { (ogData: [OpenGraphMetadata.RawValue: String]) -> Promise<PostModel> in
                if !ogData.isEmpty {
                    post.OpenGraphDictionary = ogData
                }
                return Promise.value(post)
            }

        }.map { (posts: [PostModel]) -> [PostModel] in
            return self.saveStories(posts)
        }
    }

    func getAndSaveCommentsForKidIDs(_ postID: Int, _ kidIDs: [Int]) -> Promise<[CommentModel]> {
        let commentIDs = self.getKidsForKidIDs(kidIDs)
        return commentIDs.compactMapValues { item in
            return item as? CommentModel
        }.then { (comment: [CommentModel]) -> Promise<[CommentModel]> in
            return self.saveComments(postID, comment)
        }
    }

    func saveStories(_ posts: [PostModel]) -> [PostModel] {
        let realm = Realm.live()

        try! realm.write {
            realm.add(posts, update: true)
        }

        return posts
    }

    func getCommentsForStoryID(_ storyID: Int) -> Promise<[CommentModel]> {
        return self.getKidsForParentID(storyID).compactMapValues { item in
            return item as? CommentModel
        }.then {
            return self.saveComments(storyID, $0)
        }
    }

    func saveComments(_ storyID: Int, _ comments: [CommentModel]) -> Promise<[CommentModel]> {
        let realm = Realm.live()

        let mappedComments = comments.map { (comment: CommentModel) -> CommentModel in
            comment.Post = realm.object(ofType: PostModel.self, forPrimaryKey: storyID)
            return comment
        }

        try! realm.write {
            realm.add(mappedComments, update: true)
        }

        return Promise.value(comments)
    }

    func getItemIDsForPage(_ page: HNScraper.PostListPageName, _ limit: Int = 30) -> Promise<[Int]> {
        guard let path = page.firebasePath else { return Promise.value([Int]()) }

        let storiesRef = dbRef.child(path).queryLimited(toFirst: UInt(limit))

        return Promise { seal in
            storiesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                seal.fulfill(snapshot.value as! [Int])
            }, withCancel: { (error) in
                seal.reject(error)
            })
        }
    }

    func getItemForID(_ itemID: Int) -> Promise<HNItem?> {
        let itemRef = dbRef.child("item").child(String(itemID))

        return Promise {seal in
            itemRef.observeSingleEvent(of: .value, with: { (itemSnapshot) in
                guard let snapshotJSON = itemSnapshot.value as? [String : Any] else {
                    seal.fulfill(nil); return
                }

                seal.fulfill(HNItem(JSON: snapshotJSON))
            }) { (error) in
                seal.reject(error)
            }
        }
    }

    func getKidsForParentID(_ itemID: Int) -> Promise<[HNItem]> {
        return firstly {
            self.getItemForID(itemID).compactMap { $0 }.map { Array($0.kidsIds) }
        }.then { ids in
            return self.getKidsForKidIDs(ids)
        }
    }

    func getKidsForKidIDs(_ itemIDs: [Int]) -> Promise<[HNItem]> {
        return Promise.value(itemIDs).thenMap { ids in
            self.getItemForID(ids).compactMap { $0 }
        }
    }

    private func getPostThumbnailURL(_ urlStr: String) -> Promise<URL?> {
        print("Getting OG data!")

        guard let fallbackURL = URL(string: "https://image-extractor.now.sh/?url=" + urlStr) else {
            print("Couldn't even construct fallback URL, the input URL \(urlStr) must be entirely invalid, not attempting to get thumbnail")
            return Promise.value(nil)
        }

        guard let linkURL = URL(string: urlStr) else {
            print("URL string was not convertible to a URL, not attempting to get thumbnail", urlStr)
            return Promise.value(fallbackURL)
        }

        return Promise { seal in
            OpenGraph.fetch(url: linkURL) { (og, error) in
                if let error = error {
                    print("Got error while getting OpenGraph data, returning Image Extractor URL", error)
                    seal.fulfill(fallbackURL)
                    return
                }

                guard let ogImageURLStr = og?[.image] else {
                    print("Got Open Graph info but no image found, returning Image Extractor URL", urlStr, og)
                    seal.fulfill(fallbackURL)
                    return
                }

                if !ogImageURLStr.hasPrefix("http") {
                    // og:image is something like /logo.png so we need to prefix it with the base URL for a valid URL.
                    seal.fulfill(URL(string: ogImageURLStr, relativeTo: linkURL))
                    return
                }

                seal.fulfill(URL(string: ogImageURLStr))
                return
            }
        }
    }

    private func getPostMetadata(_ urlStr: String) -> Promise<[OpenGraphMetadata.RawValue: String]> {
        guard let linkURL = URL(string: urlStr) else {
            print("URL string was not convertible to a URL, not attempting to get Open Graph data", urlStr)
            return Promise.value([:])
        }

        return Promise { seal in
            OpenGraph.fetch(url: linkURL) { (og, error) in
                if let error = error {
                    print("Got error while getting OpenGraph data, returning early", error)
                    seal.fulfill([:])
                    return
                }

                guard let ogData = og else {
                    print("Could not unwrap Open Graph response")
                    seal.fulfill([:])
                    return
                }

                var ogDict: [OpenGraphMetadata.RawValue: String] = [:]

                for ogKey in OpenGraphMetadata.allCases {
                    ogDict[ogKey] = ogData[ogKey]
                }

                seal.fulfill(ogDict)
                return
            }
        }
    }
}

extension HNScraper.PostListPageName {
    var firebasePath: String? {
        switch self {
        case .news:
            return "topstories"
        case .new:
            return "newstories"
        case .jobs:
            return "jobstories"
        case .asks:
            return "askstories"
        case .shows, .newshows:
            return "showstories"
        case .best:
            return "beststories"
        default:
            return nil
        }
    }
}
