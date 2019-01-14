//
//  PostCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift

class PostCell : UITableViewCell {

    var hasImage: Bool = false

    var post: HNPost? {
        didSet {
            guard let post = post else {
                self.titleLabel.attributedText = nil

                if self.linkStackView != nil { // cell was a link, so remove link stuff
                    self.urlLabel.setTitle(nil, for: .normal)
                    self.previewImageView.image = nil

                    let heightConstraint = self.previewImageView.constraints.first(where: { $0.identifier == "ImageHeight" })
                    heightConstraint?.constant = 300
                } else if let view = self.postTextView { // cell was text, so remove text
                    view.text = nil
                }

                self.pointsLabel.attributedText = nil
                self.commentsLabel.attributedText = nil
                self.usernameLabel.attributedText = nil
                self.timeLabel.attributedText = nil

                self.urlIcon.image = UIImage(named: "safari")

                return
            }

            self.titleLabel.attributedText = post.AttributedTitle

            self.pointsLabel.attributedText = self.generateAttributedString(String(post.Score ?? 0), .arrowUp, .solid)

            self.commentsLabel.attributedText = self.generateAttributedString(String(post.TotalChildren), .comment, .regular)

            self.timeLabel.attributedText = self.generateAttributedString(post.RelativeDate, .clock, .regular)

            self.setUsername()

            if let postText = post.Text {
                if let view = self.linkStackView {
                    self.postContentStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                if let view = self.postTextView {
                    view.text = postText
                }
            } else {
                self.hasImage = true
                if let view = self.postTextView {
                    self.postContentStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                self.urlLabel.setTitle(post.LinkForDisplay, for: .normal)

                if post.LinkIsYCDomain {
                    self.urlIcon.image = UIImage(named: "ycombinator-logo")
                }

                if let view = self.previewImageView {
                    let heightConstraint = self.previewImageView.constraints.first(where: { $0.identifier == "ImageHeight" })

                    guard UserDefaults.standard.hidePreviewImage == false else {
                        heightConstraint?.constant = 0

                        if let urlView = self.urlIcon {
                            urlView.roundCorners(corners: [.topLeft, .bottomLeft], radius: 9.0)
                        }

                        if let labelView = self.urlLabel {
                            labelView.roundCorners(corners: [.topRight, .bottomRight], radius: 9.0)
                        }
                        return
                    }

                    view.kf.setImage(with: post.ThumbnailImageResource) { (image, _, _, _) in
                        if let image = image {

                            let newHeight = view.frame.size.width / image.size.width * image.size.height

                            heightConstraint?.constant = newHeight

                            view.frame.size = CGSize(width: view.frame.width, height: newHeight)

                            view.roundCorners(corners: [.topLeft, .topRight], radius: 9.0)

                            if let iconView = self.urlIcon {
                                iconView.roundCorners(corners: [.bottomLeft], radius: 9.0)
                            }

                            if let labelView = self.detailImageView {
                                labelView.roundCorners(corners: [.bottomRight], radius: 9.0)
                            }
                        } else {
                            view.image = nil

                            heightConstraint?.constant = 0

                            if let urlView = self.urlIcon {
                                urlView.roundCorners(corners: [.topLeft, .bottomLeft], radius: 9.0)
                            }

                            if let labelView = self.detailImageView {
                                labelView.roundCorners(corners: [.topRight, .bottomRight], radius: 9.0)
                            }
                        }

                        // self.setNeedsLayout()
                        self.layoutIfNeeded()
                    }
                }
            }
        }
    }
    var delegate: PostCellDelegate?

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var postContentStackView: UIStackView!

    @IBOutlet weak var linkStackView: UIStackView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var urlDescStackView: UIStackView!
    @IBOutlet weak var urlIcon: UIImageView!
    @IBOutlet weak var urlLabel: UIButton!
    @IBOutlet weak var detailImageView: UIImageView!

    @IBOutlet weak var postTextView: UITextView!

    @IBOutlet weak var metadataStackView: UIStackView!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!

    @IBAction func upvoteTapped(_ sender: UIButton) {
        print("Upvote tapped")
    }

    @IBAction func moreTapped(_ sender: UIButton) {
        print("More tapped")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(PostCell.cellLongPress)))

        setupTheming()
        setupGestures()
    }
    
    private func setupGestures() {
        if let view = self.linkStackView {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapLinkView(_:)))
            view.addGestureRecognizer(tapGestureRecognizer)
        }

        if let view = self.usernameLabel {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapUsername(_:)))
            view.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? setSelectedBackground() : setUnselectedBackground()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? setSelectedBackground() : setUnselectedBackground()
    }
    
    func setSelectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
    }
    
    func setUnselectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
    }
    
    @objc func didTapLinkView(_ sender: Any) {
        delegate?.didTapThumbnail(sender)
    }

    @objc func cellLongPress(_ sender: Any) {
        delegate?.didLongPressCell(sender)
    }

    @objc func didTapUsername(_ sender: Any) {
        print("Username tapped!", self.post!.Author!)
        delegate?.didTapUsername(self.post!.Author!)
    }

    override func prepareForReuse() {
        self.post = nil
        self.previewImageView.kf.cancelDownloadTask()
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

    func setUsername() {
        guard let author = post?.Author else { return }

        let username = NSMutableAttributedString()

        username.append(NSAttributedString(string: "by ", attributes: [
            .foregroundColor: AppThemeProvider.shared.currentTheme.textColor,
        ]))
        username.append(author.AttributedUsername)

        self.usernameLabel.attributedText = username
    }
}

extension PostCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        self.backgroundColor = theme.backgroundColor

        self.titleLabel.textColor = theme.textColor
        self.urlLabel.setTitleColor(theme.textColor, for: .normal)
        self.pointsLabel.textColor = theme.textColor
        self.commentsLabel.textColor = theme.textColor
        self.timeLabel.textColor = theme.textColor

        self.urlLabel.backgroundColor = theme.barBackgroundColor
        self.urlIcon.backgroundColor = theme.barBackgroundColor
        self.detailImageView.backgroundColor = theme.barBackgroundColor

        // Do NOT set the username label text color directly because that will override green/orange
        // self.usernameLabel.textColor = theme.textColor
        self.setUsername()

        self.urlIcon.tintColor = theme.textColor
        self.detailImageView.tintColor = theme.textColor

        self.upvoteButton.tintColor = theme.textColor
        self.moreButton.tintColor = theme.textColor
    }
}
