//
//  Post.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import Kingfisher
import OpenGraph
import HNScraper

class PostModel: HNItem {

    /// URL of the story.
    @objc dynamic var URLString: String?

    @objc dynamic var NotifiedAt: Date?

    @objc dynamic var ThumbnailURLString: String = ""

    let Comments = LinkingObjects(fromType: CommentModel.self, property: "Post")

    convenience init(_ post: HNPost) {
        self.init()

        if let intID = Int(string: post.id) {
            self.ID = intID
        } else {
            print("Unable to cast string ID to int", post.description)
        }

        // FIXME: Convert HNScraper post type to HNItem type.
        // self.type = post.type
        self.author = post.username
        if let url = post.url {
            self.URLString = url.absoluteString
        }
        self.title = post.title
        self.score.value = Int(post.points)
        self.descendants.value = Int(post.commentCount)
    }

    override public func mapping(map: Map) {
        super.mapping(map: map)

        URLString         <- map["url"]
    }

    func MarkAsRead() {
        let realm = Realm.live()

        try! realm.write {
            self.ReadAt = Date()
        }
    }

    var OriginalPost: HNPost {
        let newPost = HNPost()
        // FIXME: Convert HNItem type to HNScraper post type.
        // newPost.type = HNPost.PostType(index: self.`Type`)!

        newPost.username = self.author!
        newPost.url = self.LinkURL
        newPost.title = self.title!
        newPost.points = self.score.value!
        newPost.commentCount = self.descendants.value!
        newPost.id = self.ID.description

        return newPost
    }

    /// URL of the story.
    var LinkURL: URL {
        return URL(string: self.URLString!)!
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.title!, self.LinkURL], applicationActivities: nil)
    }

    var LinkIsYCDomain: Bool {
        return self.URLString!.contains("ycombinator.com")
    }

    var CommentsActivityViewController: UIActivityViewController {
        // FIXME: Needs the correct comment title
        return UIActivityViewController(activityItems: [self.ItemPageTitle,
                                                        self.ItemURL], applicationActivities: nil)
    }

    var ThumbnailCacheKey: String {
        return self.ID.description
    }

    var ThumbnailFileURL: URL {
        return URL(fileURLWithPath: ImageCache.default.cachePath(forKey: self.ThumbnailCacheKey))
    }

    func ThumbnailURL(_ handler: @escaping (URL?) -> Void) {
        var imageURL = URL(string: "https://image-extractor.now.sh/?url=" + self.URLString!)!

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
