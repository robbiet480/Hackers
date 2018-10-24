//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit

protocol PostTitleViewDelegate {
    func didPressLinkButton(_ post: PostModel)
}

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    
    var isTitleTapEnabled = false
    
    var delegate: PostTitleViewDelegate?
    
    var post: PostModel? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title!
            metadataLabel.attributedText = metadataText(for: post)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        
        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
    }
    
    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
    
    private func domainLabelText(for post: PostModel) -> String? {
        guard let urlString = post.URLString else { return nil }

        guard let urlComponents = URLComponents(string: urlString), var host = urlComponents.host else {
            return nil
        }
        
        if host.starts(with: "www.") {
            host = String(host[4...])
        }
        
        return host
    }
    
    private func metadataText(for post: PostModel) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        let pointsIconAttachment = textAttachment(for: "PointsIcon")
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)
        
        let commentsIconAttachment = textAttachment(for: "CommentsIcon")
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)
        
        string.append(NSAttributedString(string: post.score.value!.description))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: "• \(post.Comments.count)"))
        string.append(commentsIconAttributedString)
        if let domainText = domainLabelText(for: post), domainText != "news.ycombinator.com" {
            string.append(NSAttributedString(string: " • \(domainText)"))
        }
        
        return string
    }
    
    private func templateImage(named: String) -> UIImage? {
        let image = UIImage.init(named: named)
        let templateImage = image?.withRenderingMode(.alwaysTemplate)
        return templateImage
    }
    
    private func textAttachment(for imageNamed: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        guard let image = templateImage(named: imageNamed) else { return attachment }
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return attachment
    }
}

extension PostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel.textColor = theme.titleTextColor
        titleLabel.font = UIFont.mySystemFont(ofSize: 18.0)
        metadataLabel.textColor = theme.textColor
        metadataLabel.font = UIFont.mySystemFont(ofSize: 14.0)
    }
}
