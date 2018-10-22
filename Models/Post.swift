//
//  Post.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import Kingfisher
import OpenGraph
import HNScraper

class PostModel: Object {
    @objc dynamic var `Type`: Int = HNPost.PostType.defaultType.hashValue
    @objc dynamic var Username: String = ""
    @objc dynamic var URLString: String = ""
    @objc dynamic var Title: String = ""
    @objc dynamic var Points: Int = 0
    @objc dynamic var CommentCount: Int = 0
    @objc dynamic var ID: Int = 0
    @objc dynamic var TimeCreatedString: String = ""
    @objc dynamic var UpvoteURLAddition: String = ""

    @objc dynamic var CreatedAt: Date = Date()

    @objc dynamic var ReadAt: Date?

    @objc dynamic var NotifiedAt: Date?

    @objc dynamic var ThumbnailURLString: String = ""

    let Comments = LinkingObjects(fromType: CommentModel.self, property: "Post")

    override static func primaryKey() -> String? {
        return "ID"
    }

    convenience init(_ post: HNPost) {
        self.init()

        if let intID = Int(string: post.id) {
            self.ID = intID
        } else {
            print("Unable to cast string ID to int", post.id, post)
        }

        self.`Type` = post.type.hashValue
        self.Username = post.username
        if let url = post.url {
            self.URLString = url.absoluteString
        }
        self.Title = post.title
        self.Points = Int(post.points)
        self.CommentCount = Int(post.commentCount)
        self.TimeCreatedString = post.time
        if let upvoteAdditionURL = post.upvoteAdditionURL {
            self.UpvoteURLAddition = upvoteAdditionURL
        }
    }

    func MarkAsRead() {
        let realm = Realm.live()

        try! realm.write {
            self.ReadAt = Date()
        }
    }

    var OriginalPost: HNPost {
        let newPost = HNPost()
        newPost.type = HNPost.PostType(index: self.`Type`)!
        newPost.username = self.Username
        newPost.url = self.LinkURL
        newPost.title = self.Title
        newPost.points = self.Points
        newPost.commentCount = self.CommentCount
        newPost.id = self.ID.description
        newPost.time = self.TimeCreatedString
        newPost.upvoteAdditionURL = self.UpvoteURLAddition

        return newPost
    }

    var LinkURL: URL {
        return URL(string: self.URLString)!
    }

    var CommentsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.ID.description)!
    }

    var CommentsPageTitle: String {
        return self.Title + " | Hacker News"
    }

    var CommentsActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.CommentsPageTitle,
                                                        self.CommentsURL], applicationActivities: nil)
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.Title,
                                                        self.LinkURL], applicationActivities: nil)
    }

    var LinkIsYCDomain: Bool {
        return self.URLString.contains("ycombinator.com")
    }

    var ThumbnailCacheKey: String {
        return self.ID.description
    }

    var ThumbnailFileURL: URL {
        return URL(fileURLWithPath: ImageCache.default.cachePath(forKey: self.ThumbnailCacheKey))
    }

    func ThumbnailURL(_ handler: @escaping (URL?) -> Void) {
        var imageURL = URL(string: "https://image-extractor.now.sh/?url=" + self.URLString)!

        OpenGraph.fetch(url: self.LinkURL) { (og, error) in
            if let image = og?[.image], let ogImageURL = URL(string: image) {
                imageURL = ogImageURL
            }

            handler(imageURL)
            return
        }
    }

    var ThumbnailImageResource: ImageResource? {
        if let url = URL(string: self.ThumbnailURLString) {
            return ImageResource(downloadURL: url, cacheKey: self.ThumbnailCacheKey)
        }

        return nil
    }

    func Thumbnail(_ needsPNG: Bool = false, handler: @escaping (UIImage?) -> Void) {
        if self.LinkIsYCDomain {
            if needsPNG, let url = Bundle.main.url(forResource: "ycombinator-logo", withExtension: "png") {
                handler(UIImage(contentsOfFile: url.path))
                return
            }

            handler(UIImage(named: "ycombinator-logo"))
            return
        }

        if let ir = self.ThumbnailImageResource {
            KingfisherManager.shared.retrieveImage(with: ir, options: nil, progressBlock: nil) { (image, error, cacheType, kfURL) in
                if let error = error {
                    print("Error when getting thumbnail for post", self.ID, "with img url", kfURL, error.debugDescription)
                    handler(nil)
                    return
                }

                handler(image)
                return
            }
        }
    }
}
