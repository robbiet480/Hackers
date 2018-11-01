//
//  CommentsController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class CommentsController {
    var comments: [HNComment]
    
    var visibleComments: [HNComment] {
        get {
            return comments.filter { $0.Visibility != HNItem.ItemVisibilityType.Hidden }
        }
    }

    convenience init() {
        self.init(source: [HNComment]())
    }
    
    init(source: [HNComment]) {
        comments = source
    }
    
    func toggleCommentChildrenVisibility(_ comment: HNComment) -> ([IndexPath], HNItem.ItemVisibilityType) {
        let visible = comment.Visibility == HNItem.ItemVisibilityType.Visible
        let visibleIndex = indexOfComment(comment, source: visibleComments)!
        let commentIndex = indexOfComment(comment, source: comments)!
        let childrenCount = countChildren(comment)
        var modifiedIndexPaths = [IndexPath]()

        comment.Visibility = visible ? .Compact : .Visible

        // Fire hide/show to HN.
        if visible {
            _ = comment.Hide()
        } else {
            _ = comment.Show()
        }

        var currentIndex = visibleIndex + 1;
        
        if childrenCount > 0 {
            for i in 1...childrenCount {
                let currentComment = comments[commentIndex + i]
                
                if visible && currentComment.Visibility == HNItem.ItemVisibilityType.Hidden { continue }

                currentComment.Visibility = visible ? HNItem.ItemVisibilityType.Hidden : HNItem.ItemVisibilityType.Visible

                modifiedIndexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex += 1
            }
        }
        
        return (modifiedIndexPaths, visible ? .Hidden : .Visible)
    }
    
    func indexOfComment(_ comment: HNComment, source: [HNComment]) -> Int? {
        for (index, value) in source.enumerated() {
            if comment.ID == value.ID { return index }
        }
        return nil
    }
    
    func countChildren(_ comment: HNComment) -> Int {
        let startIndex = indexOfComment(comment, source: comments)! + 1
        var count = 0
        
        // if last comment, there are no children
        guard startIndex < comments.count else {
            return 0
        }
        
        for i in startIndex...comments.count - 1 {
            let currentComment = comments[i]
            if currentComment.Level > comment.Level {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }
}
