//
//  NewPostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import RealmSwift
import FontAwesome_swift

protocol NewPostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost)
}

class NewPostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var urlLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!

    var isTitleTapEnabled = false
    
    var delegate: NewPostTitleViewDelegate?

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            if let link = post.Link {
                self.urlLabel.text = link.host!.replacingOccurrences(of: "www.", with: "") + link.path
            }

            if let author = post.Author {
                self.authorLabel.text = "by " + author.Username

                if let color = author.Color {
                    self.authorLabel.textColor = color
                }
            }

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

        let pointsIconAttachment = fakAttachment(for: .arrowUp, style: .solid, color: textColor)
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)

        let commentsIconAttachment = fakAttachment(for: .comment, style: .regular, color: textColor)
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)

        let timeIconAttachment = fakAttachment(for: .clock, style: .regular, color: textColor)
        let timeIconAttributedString = NSAttributedString(attachment: timeIconAttachment)

        string.append(pointsIconAttributedString)
        string.append(NSAttributedString.generate(from: String(post.Score ?? 0), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString.generate(from: String(post.TotalChildren), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(timeIconAttributedString)
        string.append(NSAttributedString.generate(from: String(post.RelativeDate), color: textColor))

        return string
    }

    private func fakAttachment(for fakIcon: FontAwesome, style: FontAwesomeStyle, color: UIColor) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let image = UIImage.fontAwesomeIcon(name: fakIcon, style: style, textColor: color,
                                            size: CGSize(width: 16, height: 16))

        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return attachment
    }
}

extension NewPostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel.textColor = theme.titleTextColor
        titleLabel.font = UIFont.mySystemFont(ofSize: 18.0)
        // metadataLabel.textColor = theme.textColor
        // metadataLabel.font = UIFont.mySystemFont(ofSize: 14.0)
    }
}
