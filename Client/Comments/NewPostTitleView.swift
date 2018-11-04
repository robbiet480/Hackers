//
//  NewPostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import FontAwesome_swift

protocol NewPostTitleViewDelegate {
    func didPressActionButton(_ action: ActionButton, _ sender: UIBarButtonItem) -> Bool
    func didPressLinkButton()
    func didTapAuthorLabel()
}

public enum ActionButton: Int, CaseIterable {
    case Vote
    case Favorite
    case Reply
    case Share
    case Flag
}

// Non system action bar icons from https://linearicons.com/free

class NewPostTitleView: UIView, UIGestureRecognizerDelegate {

    @IBOutlet var stackView: UIStackView!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var postTextView: UITextView!

    @IBOutlet var linkView: UIView!
    @IBOutlet var urlLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView!

    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!

    @IBOutlet var actionToolbar: UIToolbar!
    @IBOutlet var upvoteButton: UIBarButtonItem!
    @IBOutlet var favoriteButton: UIBarButtonItem!
    @IBOutlet var replyButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var flagButton: UIBarButtonItem!

    @IBAction func upvoteButtonTapped(_ sender: UIBarButtonItem) {
        if let worked = delegate?.didPressActionButton(.Vote, sender), worked {
            print("Change upvote button state, action worked!", self.post)
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "arrow-up")!.withRenderingMode(.alwaysTemplate), for: .normal)
            button.imageView?.tintColor = AppThemeProvider.shared.currentTheme.barBackgroundColor
            button.layer.backgroundColor = AppThemeProvider.shared.currentTheme.barForegroundColor.cgColor
            button.layer.cornerRadius = 4.0
            button.addTarget(self, action: #selector(upvoteButtonTapped(_:)), for: .touchUpInside)

            self.actionToolbar.items![0] = UIBarButtonItem(customView: button)
        }
    }

    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        if let worked = delegate?.didPressActionButton(.Favorite, sender), worked {
            print("Change favorite button state, action worked!")
        }
    }

    @IBAction func replyButtonTapped(_ sender: UIBarButtonItem) {
        if let worked = delegate?.didPressActionButton(.Reply, sender), worked {
            print("Change reply button state, action worked!")
        }
    }

    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        if let worked = delegate?.didPressActionButton(.Share, sender), worked {
            print("Change share button state, action worked!")
        }
    }

    @IBAction func flagButtonTapped(_ sender: UIBarButtonItem) {
        if let worked = delegate?.didPressActionButton(.Flag, sender), worked {
            print("Change flag button state, action worked!")
        }
    }

    var delegate: NewPostTitleViewDelegate?

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            if let author = post.Author {
                self.authorLabel.text = author.Username
                self.authorLabel.textColor = author.Color
            }

            self.titleLabel.text = post.Title

            self.metadataLabel.attributedText = self.metadataText(post)

            if let postText = post.Text {
                print("Setting post text!")
                let postTextFont = UIFont.mySystemFont(ofSize: 18.0)
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

                stackView.removeArrangedSubview(self.linkView)
                self.linkView.removeFromSuperview()
                // linkView.isHidden = true
                // postTextView.isHidden = false
            } else if let link = post.Link, !post.LinkIsYCDomain {
                print("Setting post link")
                stackView.removeArrangedSubview(self.postTextView)
                self.postTextView.removeFromSuperview()
                // postTextView.isHidden = true
                // linkView.isHidden = false
                thumbnailImageView.setImage(post)
                self.urlLabel.text = link.host!.replacingOccurrences(of: "www.", with: "") + link.path
            }
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
        urlLabel.addGestureRecognizer(titleTapGestureRecognizer)
        thumbnailImageView.addGestureRecognizer(titleTapGestureRecognizer)

        let authorTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressAuthorText(_:)))
        authorLabel.addGestureRecognizer(authorTapGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(PostTitleView.handleRealtimeUpdate(_:)),
                                               name: HNRealtime.shared.PostUpdatedNotificationName, object: nil)
    }

    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        delegate?.didPressLinkButton()
    }

    @objc func didPressAuthorText(_ sender: UITapGestureRecognizer) {
        delegate?.didTapAuthorLabel()
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
        titleLabel.font = UIFont.myBoldSystemFont(ofSize: 18.0)

        actionToolbar.barTintColor = theme.barBackgroundColor
        actionToolbar.tintColor = theme.barForegroundColor

        //postTextView.backgroundColor = theme.backgroundColor
        postTextView.font = UIFont.mySystemFont(ofSize: 16.0)
    }
}
