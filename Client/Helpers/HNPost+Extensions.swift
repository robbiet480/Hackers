//
//  HNPost+Extensions.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation
import Kingfisher
import OpenGraph

extension HNPost {
    var LinkURL: URL {
        return URL(string: self.urlString)!
    }

    var CommentsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.postId)!
    }

    var CommentsPageTitle: String {
        return self.title + " | Hacker News"
    }

    var CommentsActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.CommentsPageTitle,
                                                        self.CommentsURL], applicationActivities: nil)
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.title,
                                                        self.LinkURL], applicationActivities: nil)
    }

    var ThumbnailCacheKey: String {
        return self.postId! != "" ? self.postId! : self.urlString!
    }

    var ThumbnailFileURL: URL {
        return URL(fileURLWithPath: ImageCache.default.cachePath(forKey: self.ThumbnailCacheKey))
    }

    func ThumbnailURL(_ handler: @escaping (URL?) -> Void) {
        var imageURL = URL(string: "https://image-extractor.now.sh/?url=" + self.urlString)!

        OpenGraph.fetch(url: self.LinkURL) { (og, error) in
            if let image = og?[.image], let ogImageURL = URL(string: image) {
                imageURL = ogImageURL
            }

            handler(imageURL)
            return
        }
    }

    func ThumbnailImageResource(_ handler: @escaping (ImageResource?) -> Void) {
        self.ThumbnailURL { (url) in
            if let url = url {
                handler(ImageResource(downloadURL: url, cacheKey: self.ThumbnailCacheKey))
                return
            }
            handler(nil)
            return
        }
    }

    var LinkIsYCDomain: Bool {
        return self.urlString.contains("ycombinator.com")
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

        self.ThumbnailImageResource { (imageResource) in
            if let imageResource = imageResource {
                KingfisherManager.shared.retrieveImage(with: imageResource, options: nil, progressBlock: nil) { (image, error, cacheType, kfURL) in
                    if let error = error {
                        print("Error when getting thumbnail for post", self.postId, "with img url", kfURL, error.debugDescription)
                        handler(nil)
                        return
                    }

                    handler(image)
                    return
                }
            } else {
                print("Unable to get image resource")
                handler(nil)
                return
            }
        }
    }
}
