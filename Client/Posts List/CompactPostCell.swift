//
//  PostCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

protocol PostCellDelegate {
    func didTapThumbnail(_ sender: Any)
    func didLongPressCell(_ sender: Any)
}

protocol PostTitleViewCellDelegate {
    func didChangeMetadata()
}

class CompactPostCell : UITableViewCell {
    var post: HNPost?
    var delegate: PostCellDelegate?
    
    @IBOutlet var postTitleView: PostTitleView!
    @IBOutlet var previewImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(PostCell.cellLongPress)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        setupThumbnailGesture()
    }
    
    private func setupThumbnailGesture() {
        if let previewImageView = previewImageView {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapThumbnail(_:)))
            previewImageView.addGestureRecognizer(tapGestureRecognizer)
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
        self.postTitleView.post = nil
        self.postTitleView.hideDomain = false
        self.postTitleView.hideUsername = false
        self.postTitleView.delegate = nil

        let placeholder = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        previewImageView.image = placeholder
    }
}

extension CompactPostCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
    }
}
