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
    var post: HNPost? {
        didSet {
            guard let post = post else {
                self.titleLabel.attributedText = nil

                if self.linkStackView != nil { // cell was a link, so remove link stuff
                    self.urlLabel.text = nil
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

                return
            }

            self.titleLabel.attributedText = post.AttributedTitle

            self.pointsLabel.attributedText = self.generateAttributedString(String(post.Score ?? 0), .arrowUp, .solid)

            self.commentsLabel.attributedText = self.generateAttributedString(String(post.TotalChildren), .comment, .regular)

            self.timeLabel.attributedText = self.generateAttributedString(post.RelativeDate, .clock, .regular)

            if let author = post.Author {
                let username = NSMutableAttributedString()

                username.append(NSAttributedString(string: "by "))
                username.append(author.AttributedUsername)

                self.usernameLabel.attributedText = username
            }

            if let postText = post.Text {
                if let view = self.linkStackView {
                    self.postContentStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                if let view = self.postTextView {
                    view.text = postText
                }
            } else {
                if let view = self.postTextView {
                    self.postContentStackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }

                if let label = self.urlLabel {
                    label.text = post.LinkForDisplay
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

                            if let labelView = self.urlLabel {
                                labelView.roundCorners(corners: [.bottomRight], radius: 9.0)
                            }
                        } else {
                            heightConstraint?.constant = 0

                            if let urlView = self.urlIcon {
                                urlView.roundCorners(corners: [.topLeft, .bottomLeft], radius: 9.0)
                            }

                            if let labelView = self.urlLabel {
                                labelView.roundCorners(corners: [.topRight, .bottomRight], radius: 9.0)
                            }
                        }
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
    @IBOutlet weak var urlLabel: UILabel!

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

        upvoteButton.setImage(UIImage(named: "arrow-up")?.withRenderingMode(.alwaysTemplate), for: .normal)
        upvoteButton.tintColor = AppThemeProvider.shared.currentTheme.textColor

        moreButton.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = AppThemeProvider.shared.currentTheme.textColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        setupThumbnailGesture()
    }
    
    private func setupThumbnailGesture() {
        if let view = linkStackView {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapThumbnail(_:)))
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
    
    @objc func didTapThumbnail(_ sender: Any) {
        delegate?.didTapThumbnail(sender)
    }

    @objc func cellLongPress(_ sender: Any) {
        delegate?.didLongPressCell(sender)
    }

    override func prepareForReuse() {
        self.post = nil
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

extension PostCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
    }
}
