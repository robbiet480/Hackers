//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import FontAwesome_swift

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

            self.titleLabel.text = post.Title

            self.metadataLabel.attributedText = self.metadataText(post)
        }
    }

    @objc func handleRealtimeUpdate(_ notification: Notification) {
        // print("Received update!", notification)
        if let postUpdate = notification.object as? HNPost, self.post?.ID == postUpdate.ID {
            self.post = postUpdate
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        
        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(PostTitleView.handleRealtimeUpdate(_:)),
                                               name: HNRealtime.shared.PostUpdatedNotificationName, object: nil)
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

    private func metadataText(_ post: HNPost) -> NSAttributedString {

        let string = NSMutableAttributedString()

        let textColor = AppThemeProvider.shared.currentTheme.textColor

        string.append(fakAttachment(for: .arrowUp, style: .solid))
        string.append(NSAttributedString.generate(from: String(post.Score ?? 0), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(fakAttachment(for: .comment, style: .regular))
        string.append(NSAttributedString(string: " "))
        string.append(NSAttributedString.generate(from: String(post.TotalChildren), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(fakAttachment(for: .clock, style: .regular))
        string.append(NSAttributedString(string: " "))
        string.append(NSAttributedString.generate(from: String(post.RelativeDate), color: textColor))
        if let author = post.Author {
            string.append(NSAttributedString(string: " "))
            string.append(fakAttachment(for: .userAlt, style: .solid))
            string.append(NSAttributedString(string: " "))
            string.append(NSAttributedString.generate(from: author.Username, color: author.Color))
        }
        if let domainText = domainLabelText(for: post), domainText != "news.ycombinator.com" {
            string.append(NSAttributedString(string: "\n"))
            string.append(fakAttachment(for: .globeAmericas, style: .solid))
            string.append(NSAttributedString(string: " "))
            string.append(NSAttributedString(string: domainText))
        }

        return string
    }

    private func fakAttachment(for fakIcon: FontAwesome, style: FontAwesomeStyle) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let image = UIImage.fontAwesomeIcon(name: fakIcon, style: style,
                                            textColor: AppThemeProvider.shared.currentTheme.textColor,
                                            size: CGSize(width: 16, height: 16))

        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return NSAttributedString(attachment: attachment)
    }
}

extension PostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel.textColor = theme.titleTextColor
        titleLabel.font = UIFont.mySystemFont(ofSize: 18.0)
        if let post = post {
            self.metadataLabel.attributedText = self.metadataText(post)
        }
//        metadataLabel.textColor = theme.textColor
//        metadataLabel.font = UIFont.mySystemFont(ofSize: 14.0)
    }
}

// MARK: Extension util which generates NSAttributedString by text,font,color,backgroundColor
extension NSAttributedString {
    class func generate(from text: String, font: UIFont = UIFont.systemFont(ofSize: 14), color: UIColor = .black,
                        backgroundColor: UIColor = .clear) -> NSAttributedString {
        let atts: [NSAttributedString.Key : Any] = [.foregroundColor: color, .font: font,
                                                    .backgroundColor: backgroundColor]
        return NSAttributedString(string: text, attributes: atts)
    }
}
