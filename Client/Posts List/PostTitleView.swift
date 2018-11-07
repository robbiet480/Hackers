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
    func didTapUsername(_ user: HNUser)
    func didTapDomain(_ domainName: String)
}

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var metadataStackView: UIStackView!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var domainLabel: UILabel!

    var isTitleTapEnabled = false
    
    var delegate: PostTitleViewDelegate?
    var cellDelegate: PostTitleViewCellDelegate?

    var hideUsername: Bool = false {
        didSet {
            self.usernameLabel.isHidden = hideUsername
        }
    }
    var hideDomain: Bool = false {
        didSet {
            self.domainLabel.isHidden = hideDomain
        }
    }

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            if let oldValue = oldValue, oldValue.Flagged == true && post.Flagged == false {
                post.Flagged = true
            }

            if let oldValue = oldValue, let oldAuthor = oldValue.Author, let newAuthor = post.Author {
                if oldAuthor.IsYC == true && newAuthor.IsYC == false {
                    newAuthor.IsYC = true
                }
                if oldAuthor.IsNew == true && newAuthor.IsNew == false {
                    newAuthor.IsNew = true
                }
            }

            if post.Title != nil {
                self.titleLabel.attributedText = post.AttributedTitle
            }

            self.pointsLabel.attributedText = self.generateAttributedString(String(post.Score ?? 0), .arrowUp, .solid)

            self.commentsLabel.attributedText = self.generateAttributedString(String(post.TotalChildren), .comment, .regular)

            self.timeLabel.attributedText = self.generateAttributedString(post.RelativeDate, .clock, .regular)

            if let author = post.Author {
                let username = NSMutableAttributedString()

                username.append(fakAttachment(for: .userAlt, style: .solid))
                username.append(author.AttributedUsername)

                self.usernameLabel.attributedText = username
                self.usernameLabel.font = UIFont.mySystemFont(ofSize: 14)
            }

            if let domain = post.Domain {
                self.domainLabel.attributedText = self.generateAttributedString(domain, .globeAmericas, .solid)
            } else {
                self.domainLabel.isHidden = true
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

        if let titleLabel = titleLabel {
            let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
            titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
        }

        if let usernameLabel = usernameLabel {
            let usernameTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(usernameTapped(_:)))
            usernameLabel.addGestureRecognizer(usernameTapGestureRecognizer)
        }

        if let domainLabel = domainLabel {
            let domainTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(domainTapped(_:)))
            domainLabel.addGestureRecognizer(domainTapGestureRecognizer)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(PostTitleView.handleRealtimeUpdate(_:)),
                                               name: HNRealtime.shared.PostUpdatedNotificationName, object: nil)
    }

    @objc func usernameTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapUsername(self.post!.Author!)
    }

    @objc func domainTapped(_ sender: UITapGestureRecognizer) {
        delegate?.didTapDomain(self.post!.Domain!)
    }

    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = delegate {
            delegate.didPressLinkButton(self.post!)
        }
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

    func generateAttributedString(_ value: String, _ icon: FontAwesome, _ style: FontAwesomeStyle) -> NSMutableAttributedString {
        let string = NSMutableAttributedString()

        string.append(fakAttachment(for: icon, style: style))
        string.append(NSAttributedString.generate(from: value))

        return string
    }
}

extension PostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {}
}

// MARK: Extension util which generates NSAttributedString by text,font,color,backgroundColor
extension NSAttributedString {
    class func generate(from text: String) -> NSAttributedString {
        let atts: [NSAttributedString.Key : Any] = [.foregroundColor: AppThemeProvider.shared.currentTheme.textColor,
                                                    .backgroundColor: UIColor.clear]
        return NSAttributedString(string: text, attributes: atts)
    }
}
