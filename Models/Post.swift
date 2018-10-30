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

    /// The time at which the user favorited the story
    @objc dynamic var FavoritedAt: Date?

    @objc private dynamic var openGraphData: Data?

    /// Open Graph Metadata for the URL
    var OpenGraphDictionary: [OpenGraphMetadata.RawValue: String] {
        get {
            guard let openGraphData = openGraphData else {
                return [OpenGraphMetadata.RawValue: String]()
            }
            do {
                let dict = try JSONSerialization.jsonObject(with: openGraphData, options: []) as? [OpenGraphMetadata.RawValue: String]
                return dict!
            } catch {
                return [OpenGraphMetadata.RawValue: String]()
            }
        }

        set {
            do {
                let data = try JSONSerialization.data(withJSONObject: newValue, options: [])
                openGraphData = data as Data
            } catch {
                openGraphData = nil
            }
        }
    }

    @objc dynamic var NotifiedAt: Date?

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
        self.descendants = Int(post.commentCount)
    }

    override public func mapping(map: Map) {
        super.mapping(map: map)

        URLString         <- map["url"]
    }

    override static func ignoredProperties() -> [String] {
        return ["OpenGraphDictionary"]
    }

    func MarkAsRead() {
        let realm = Realm.live()

        try! realm.write {
            self.ReadAt = Date()
        }
    }

    /// URL of the story.
    var LinkURL: URL {
        return URL(string: self.URLString!)!
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.title!, self.LinkURL], applicationActivities: nil)
    }

    var LinkIsYCDomain: Bool {
        guard let urlStr = self.URLString else { return false }
        return urlStr.contains("ycombinator.com")
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

    var ThumbnailURL: URL? {
        guard let urlStr = self.URLString else { return nil }

        // https://drcs9k8uelb9s.cloudfront.net/ is the hn.algolia.com thumbnail cache
        // three sizes are available
        // /id.png - 100x100
        // /id-600x315.png - 600x315
        // /id-240x180.png - 240x180
        // Previous to this discovery, we used https://image-extractor.now.sh/?url=
        guard let fallbackURL = URL(string: "https://drcs9k8uelb9s.cloudfront.net/" + self.ID.description + "-600x315.png") else { return nil }

        guard let linkURL = URL(string: urlStr) else { return fallbackURL }

        var ogImageURLTest: String? = nil

        let keysToCheck: [OpenGraphMetadata] = [.image, .imageUrl, .imageSecure_url]

        for ogKey in keysToCheck {
            if let ogURL = self.OpenGraphDictionary[ogKey] {
                ogImageURLTest = ogURL
                break
            }
        }

        guard let ogImageURLStr = ogImageURLTest else {
            return fallbackURL
        }

        if !ogImageURLStr.hasPrefix("http") {
            // og:image is something like /logo.png so we need to prefix it with the base URL for a valid URL.
            return URL(string: ogImageURLStr, relativeTo: linkURL)
        }

        return URL(string: ogImageURLStr)
    }

    var ThumbnailImageResource: ImageResource? {
        if let url = self.ThumbnailURL {
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

extension Dictionary where Key: ExpressibleByStringLiteral {
    subscript<Index: RawRepresentable>(index: Index) -> Value? where Index.RawValue == String {
        get {
            return self[index.rawValue as! Key]
        }

        set {
            self[index.rawValue as! Key] = newValue
        }
    }
}
