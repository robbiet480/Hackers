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
    @IBOutlet var postTextView: UITextView!
    @IBOutlet var thumbnailImageView: UIImageView!

    var isTitleTapEnabled = false
    
    var delegate: NewPostTitleViewDelegate?

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            if let postText = post.Text {
                let postTextFont = UIFont.systemFont(ofSize: 15)
                let postTextColor = AppThemeProvider.shared.currentTheme.textColor
                let lineSpacing = 4 as CGFloat

                let postTextAttributedString = NSMutableAttributedString(string: postText.htmlDecoded)
                let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                paragraphStyle.lineSpacing = lineSpacing

                let postTextRange = NSMakeRange(0, postTextAttributedString.length)

                postTextAttributedString.addAttribute(NSAttributedString.Key.font, value: postTextFont, range: postTextRange)
                postTextAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: postTextColor, range: postTextRange)
                postTextAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: postTextRange)

                postTextView.attributedText = postTextAttributedString

                postTextView.isHidden = false
                thumbnailImageView.isHidden = true
                urlLabel.isHidden = true
            } else {
                postTextView.isHidden = true
                thumbnailImageView.isHidden = false
                urlLabel.isHidden = false
                thumbnailImageView.setImage(post)
                if let link = post.Link {
                    self.urlLabel.text = link.host!.replacingOccurrences(of: "www.", with: "") + link.path
                }
            }

            if let author = post.Author {
                self.authorLabel.text = author.Username
                self.authorLabel.textColor = author.Color
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

    override func awakeFromNib() {
        super.awakeFromNib()
        postTextView.isHidden = true
        thumbnailImageView.isHidden = true
        urlLabel.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()

        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
        urlLabel.addGestureRecognizer(titleTapGestureRecognizer)
        thumbnailImageView.addGestureRecognizer(titleTapGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(PostTitleView.handleRealtimeUpdate(_:)),
                                               name: HNRealtime.shared.PostUpdatedNotificationName, object: nil)
    }

    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }

    private func metadataText(_ post: HNPost) -> NSAttributedString {

        let string = NSMutableAttributedString()

        let textColor = AppThemeProvider.shared.currentTheme.textColor

        let pointsIconAttachment = fakAttachment(for: .arrowUp, style: .solid, color: textColor)
        
        let commentsIconAttachment = fakAttachment(for: .comment, style: .regular, color: textColor)
        
        let timeIconAttachment = fakAttachment(for: .clock, style: .regular, color: textColor)
        
        string.append(pointsIconAttachment)
        string.append(NSAttributedString.generate(from: String(post.Score ?? 0), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(commentsIconAttachment)
        string.append(NSAttributedString.generate(from: String(post.TotalChildren), color: textColor))
        string.append(NSAttributedString(string: " "))
        string.append(timeIconAttachment)
        string.append(NSAttributedString.generate(from: String(post.RelativeDate), color: textColor))

        return string
    }

    private func fakAttachment(for fakIcon: FontAwesome, style: FontAwesomeStyle, color: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let image = UIImage.fontAwesomeIcon(name: fakIcon, style: style, textColor: color,
                                            size: CGSize(width: 16, height: 16))

        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return NSAttributedString(attachment: attachment)
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
