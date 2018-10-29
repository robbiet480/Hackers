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
        return commentIDs.compactMapValues {
            self.processComment(postID, $0)
        }.then { comments in
            return self.saveComments(postID, comments)
        }
    }

    func processComment(_ postID: Int, _ item: HNItem?, _ level: Int = 0) -> CommentModel? {
        guard let item = item else { return nil }
        guard item.isDeleted == false else { return nil }
        guard item.isDead == false else { return nil }

        /*if item.kidsIds.count > 0 {
            print("Comment has", item.kidsIds.count, "kids, spawning a job to download them!")

            DispatchQueue.global(qos: .userInitiated).async {
                for kidID in item.kidsIds {
                    print("Spawned job for", kidID)
                    self.getAndSaveComment(postID, kidID, level + 1)
                }
            }

        }*/

//        let promises: [Promise<CommentModel>] = item.kidsIds.map {
//            self.getAndSaveComment(postID, $0, level + 1)
//        }
//
//        let finalPromise: Promise<CommentModel>? = promises.reduce(nil) { (res, comment) in
//            return res?.then { aComment in
//                print("Comment", aComment.value.ID)
//                return comment
//            }
//        }
//
//        print("finalPromise", finalPromise)

        guard let comment = item as? CommentModel else { return nil }

        comment.Level = level

        return comment
    }

    func getAndSaveComment(_ postID: Int, _ commentID: Int, _ level: Int = 0) -> Promise<CommentModel> {
        let realm = Realm.live()

        if let checkForComment = realm.object(ofType: CommentModel.self, forPrimaryKey: commentID) {
            print("Comment \(commentID) already existed!")
            return Promise.value(checkForComment)
        }

        return self.getItemForID(commentID).compactMap {
            return self.processComment(postID, $0, level)
        }.then { comment -> Promise<CommentModel> in
            return self.saveComments(postID, [comment]).firstValue
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

//    func getCommentsTree(itemID: Int, parentID: Int? = nil, level: Int = 0) -> Guarantee<[Result<[CommentModel]>]> {
//        // 1. Get the post so we get all comment IDs
//        // 2. Get every comment by its ID
//        // 3. Get all children of the comment
//        // 4. Repeat previous step for all grandchildren found in childrens
//
//        print("Getting tree for", itemID, "at level", level, "(parent id: \(parentID))")
//        let retVal = self.getItemForID(itemID).compactMap { $0 }.map { hnItem -> CommentModel? in
//            return self.mapComment(commentID: hnItem.ID, parentID: hnItem.parentId.value!, item: hnItem)
//        }.then { item -> Promise<(Int?, List<Int>?)> in
//            // ID checks
//            // If parentID in function signature is nil AND item?.parentId.value is nil, itemID is post ID
//            // If parentID in function signature is nil BUT item?.parentId.value is NOT nil, itemID is comment, item?.parentId.value is post
//            // If parentID in function signature is NOT nil AND item?.parentId.value is NOT nil, itemID is comment, parentID is post ID and item?.parentId.value is parent comment ID
//
//            let itemParentID: Int = item?.parentId.value != nil ? item!.parentId.value! : itemID
//
//            print("itemParentID", itemParentID)
//
//            let parentID = parentID != nil ? parentID : itemParentID
//
//            print("parentID", parentID)
//
//            print("CHECK PARENT ID", itemID, parentID, itemParentID)
//
//            print("Returning new IDs!")
//            return Promise.value((parentID, item?.kidsIds))
//        }.then { (item: (Int?, List<Int>?)) -> Guarantee<[Result<[CommentModel]>]> in
//            let parentID = item.0
//            let childIDs = item.1
//
//            print("CHECK PARENT ID", itemID, parentID, childIDs)
//
//            //print("Got child IDs", childIDs, "for parent ID", parentID)
//
//            let mappedPromises = Array(childIDs!).map { childID -> Promise<[CommentModel]> in
//                print("Going to call getCommentsTree with params", childID, parentID, level + 1)
//                return self.getCommentsTree(itemID: childID, parentID: parentID, level: level + 1)
//            }
//
//            let retVal = when(resolved: mappedPromises)
//            print("retVal", retVal)
//            return retVal
//        }/*.thenMap { result -> Promise<[CommentModel]> in
//            switch result {
//            case .fulfilled(let commentsArr):
//                print("Promise fulfilled with return value", commentsArr)
//                let mapped = commentsArr.map { singleComment -> CommentModel in
//                    singleComment.Level = level
//                    singleComment.parentId.value = parentID
//                    return singleComment
//                }
//                print("Mapped value", mapped)
//                return Promise.value(mapped)
//            case .rejected(let error):
//                print("Failed to get comment with error", error)
//                return Promise.value([CommentModel]())
//            }
//        }.then { models -> Promise<[CommentModel]> in
//            print("Models", models.flatMap { $0 })
//            return Promise.value(models.flatMap { $0 })
//        }*/
//
//        print("retVal", retVal)
//
//        return retVal
//    }
//
//    
//
//    func mapComment(commentID: Int, parentID: Int, item: HNItem, level: Int = 0) -> CommentModel? {
//        if let comment = item as? CommentModel {
//            let realm = Realm.live()
//
//            comment.Level = level
//            if comment.parentId.value == parentID { // ParentID should only be nil if its a post
//                comment.Post = realm.object(ofType: PostModel.self, forPrimaryKey: comment.parentId.value)
//            } else {
//                comment.parentId.value = parentID
//            }
//            print("Saving comment", comment.ID)
//
//            try! realm.write {
//                realm.add(comment, update: true)
//            }
//        }
//
//        return nil
//    }
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
