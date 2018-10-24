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
        }.map { (posts: [PostModel]) -> [PostModel] in
            return self.saveStories(posts)
        }.thenMap { (post: PostModel) -> Promise<PostModel> in
            return self.getAndSaveThumbnail(post)
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
        guard let fallbackURL = URL(string: "https://image-extractor.now.sh/?url=" + urlStr) else {
            print("Couldn't even construct fallback URL, the input URL \(urlStr) must be entirely invalid, not attempting to get thumbnail")
            return Promise.value(nil)
        }

        guard let linkURL = URL(string: urlStr) else { return Promise.value(fallbackURL) }

        return Promise { seal in
            OpenGraph.fetch(url: linkURL) { (og, error) in
                if let error = error {
                    print("Got error while getting OpenGraph data, returning Image Extractor URL", error)
                    seal.fulfill(fallbackURL)
                    return
                }

                guard let ogImageURLStr = og?[.image] else {
                    print("Got Open Graph info but no image found, returning Image Extractor URL")
                    seal.fulfill(fallbackURL)
                    return
                }

                seal.fulfill(URL(string: ogImageURLStr))
                return
            }
        }
    }

    private func getAndSaveThumbnail(_ post: PostModel) -> Promise<PostModel> {
        guard let urlStr = post.URLString else {
            print("Post does not have a URL attached, not attempting to get thumbnail", post)
            return Promise.value(post)
        }

        return self.getPostThumbnailURL(urlStr).then { (url: URL?) -> Promise<PostModel> in

            guard let absStr = url?.absoluteString else {
                print("Got a nil URL, returning early from thumbnail saver!")
                return Promise.value(post)
            }

            let realm = Realm.live()

            try! realm.write {
                post.ThumbnailURLString = absStr
            }

            return Promise.value(post)
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
