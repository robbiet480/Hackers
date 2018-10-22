//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 18/12/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import Kingfisher
import RealmSwift

extension UIImageView {
    func setImage(_ post: PostModel) {

        let placeholderImage = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        self.image = placeholderImage

        if post.LinkIsYCDomain {
            self.image = UIImage(named: "ycombinator-logo")!
        } else {
            if let ir = post.ThumbnailImageResource {
                self.kf.setImage(with: ir)
            }
        }
    }
}
