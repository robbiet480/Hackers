//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import RealmSwift

protocol PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost)
}

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    
    var isTitleTapEnabled = false
    
    var delegate: PostTitleViewDelegate?
    var cellDelegate: PostTitleViewCellDelegate?

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            let pointsChanged = oldValue?.Score != post.Score
            let commentsChanged = oldValue?.TotalChildren != post.TotalChildren

            titleLabel.text = post.Title

            self.metadataLabel.attributedText = self.metadataText(post)

            if UserDefaults.standard.animateUpdates && oldValue != nil && (pointsChanged || commentsChanged) {
                print("Post", self.post!.Title, "changed points: \(pointsChanged), comments: \(commentsChanged)")

                cellDelegate?.didChangeMetadata()

//                UIView.transition(with: self.metadataLabel,
//                                  duration: 10,
//                                  options: [],
//                                  animations: {
//                                    self.metadataLabel.attributedText = self.metadataText(post, pointsChanged,
//                                                                                          commentsChanged)
//                                    self.metadataLabel.attributedText = self.metadataText(post)
//                }, completion: nil)
            }
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
    
    private func domainLabelText(for post: HNPost) -> String? {
        guard let link = post.Link else { return nil }

        guard let urlComponents = URLComponents(url: link, resolvingAgainstBaseURL: true),
            var host = urlComponents.host else {
            return nil
        }
        
        if host.starts(with: "www.") {
            host = String(host[4...])
        }
        
        return host
    }
    
    private func metadataText(_ post: HNPost, _ pointsChanged: Bool = false,
                              _ commentsChanged: Bool = false) -> NSAttributedString {

        let string = NSMutableAttributedString()
        
        let pointsIconAttachment = textAttachment(for: "PointsIcon")
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)
        
        let commentsIconAttachment = textAttachment(for: "CommentsIcon")
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)

        let trueColor = AppThemeProvider.shared.currentTheme.barForegroundColor
        let falseColor = AppThemeProvider.shared.currentTheme.textColor

        let pointsColor = pointsChanged ? trueColor : falseColor

        let commentsColor = commentsChanged ? trueColor : falseColor

        string.append(NSAttributedString.generate(from: String(post.Score ?? 0), color: pointsColor))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: "• "))
        string.append(NSAttributedString.generate(from: String(post.TotalChildren), color: commentsColor))
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
//        metadataLabel.textColor = theme.textColor
//        metadataLabel.font = UIFont.mySystemFont(ofSize: 14.0)
    }
}

// MARK: Extension util which generates NSAttributedString by text,font,color,backgroundColor
extension NSAttributedString {
    class func generate(from text: String, font: UIFont = UIFont.systemFont(ofSize: 14), color: UIColor = .black, backgroundColor: UIColor = .clear) -> NSAttributedString {
        let atts: [NSAttributedString.Key : Any] = [.foregroundColor: color, .font: font,
                                                    .backgroundColor: backgroundColor]
        return NSAttributedString(string: text, attributes: atts)
    }
}
