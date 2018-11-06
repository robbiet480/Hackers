//
//  CommentTableViewCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class CommentTableViewCell : UITableViewCell {
    var delegate: CommentDelegate?

    var level: Int = 0 {
        didSet { updateIndentPadding() }
    }

    var post: HNPost? {
        didSet {
            guard let post = post else { return }

            if let oldValue = oldValue, let oldAuthor = oldValue.Author, let newAuthor = post.Author {
                if oldAuthor.IsYC == true && newAuthor.IsYC == false {
                    newAuthor.IsYC = true
                }
                if oldAuthor.IsNew == true && newAuthor.IsNew == false {
                    newAuthor.IsNew = true
                }
            }
        }
    }

    var comment: HNComment? {
        didSet {
            guard let comment = comment else { return }
            guard comment.Text != nil else { return }

            if let oldValue = oldValue, let oldAuthor = oldValue.Author, let newAuthor = comment.Author {
                if oldAuthor.IsYC == true && newAuthor.IsYC == false {
                    newAuthor.IsYC = true
                }
                if oldAuthor.IsNew == true && newAuthor.IsNew == false {
                    newAuthor.IsNew = true
                }
            }

            updateCommentContent(with: comment)
        }
    }

    @IBOutlet var commentTextView: TouchableTextView!
    @IBOutlet var authorLabel : UILabel!
    @IBOutlet var datePostedLabel : UILabel!
    @IBOutlet var leftPaddingConstraint : NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheming()
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CommentTableViewCell.cellTapped)))
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(CommentTableViewCell.cellLongPress)))

        if authorLabel != nil {
            authorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CommentTableViewCell.authorTapped)))
        }
    }

    @objc func cellTapped() {
        delegate?.commentTapped(self)
        setSelected(!isSelected, animated: false)
    }

    @objc func cellLongPress() {
        delegate?.commentLongPressed(self)
    }

    @objc func authorTapped() {
        delegate?.authorTapped(self.comment!.Author!)
    }

    func updateIndentPadding() {
        let levelIndent = 15
        let padding = CGFloat(levelIndent * (level + 1))
        leftPaddingConstraint.constant = padding
    }

    func updateCommentContent(with comment: HNComment) {
        level = comment.Level
        datePostedLabel.text = comment.RelativeDate

        if let author = comment.Author {
            self.authorLabel.attributedText = author.AttributedUsername
        }

        if let commentTextView = commentTextView {
            // only for expanded comments
            // let commentFont = UIFont.mySystemFont(ofSize: 15)
            var commentTextColor = AppThemeProvider.shared.currentTheme.textColor
            if UserDefaults.standard.fadeBadComments {
                commentTextColor = commentTextColor.withAlphaComponent(comment.FadeAlpha)
            }
            let lineSpacing = 4 as CGFloat
            
            let commentAttributedString = NSMutableAttributedString(string: comment.Text!.htmlDecoded)
            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = lineSpacing
            
            let commentRange = NSMakeRange(0, commentAttributedString.length)
            
            // commentAttributedString.addAttribute(NSAttributedString.Key.font, value: commentFont, range: commentRange)
            commentAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: commentTextColor, range: commentRange)
            commentAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: commentRange)
            
            commentTextView.attributedText = commentAttributedString
        }
    }
}

extension CommentTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if let delegate = delegate {
            delegate.linkTapped(URL, sender: textView)
            return false
        }
        return true
    }
}

extension CommentTableViewCell {
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
}

extension CommentTableViewCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        if commentTextView != nil {
            commentTextView.textColor = theme.textColor
            //commentTextView.font = UIFont.mySystemFont(ofSize: 15.0)
            commentTextView.linkTextAttributes = [.foregroundColor: theme.appTintColor]
        }
        /*if authorLabel != nil {
            authorLabel.font = UIFont.mySystemFont(ofSize: 15.0)
        }*/
        if datePostedLabel != nil {
            datePostedLabel.textColor = theme.lightTextColor
            // datePostedLabel.font = UIFont.mySystemFont(ofSize: 15.0)
        }
        if separatorView != nil {
            separatorView.backgroundColor = theme.separatorColor
        }
    }
}
