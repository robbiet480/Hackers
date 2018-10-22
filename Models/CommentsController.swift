//
//  CommentsController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class CommentsController {
    var comments: [CommentModel]
    
    var visibleComments: [CommentModel] {
        get {
            return comments.filter { $0.Visibility != CommentModel.VisibilityType.Hidden }
        }
    }
    
    convenience init() {
        self.init(source: [CommentModel]())
    }
    
    init(source: [CommentModel]) {
        comments = source
    }
    
    func toggleCommentChildrenVisibility(_ comment: CommentModel) -> ([IndexPath], CommentModel.VisibilityType) {
        let visible = comment.Visibility == CommentModel.VisibilityType.Visible
        let visibleIndex = indexOfComment(comment, source: visibleComments)!
        let commentIndex = indexOfComment(comment, source: comments)!
        let childrenCount = countChildren(comment)
        var modifiedIndexPaths = [IndexPath]()

        let realm = Realm.live()

        try! realm.write {
            comment.Visibility = visible ? .Compact : .Visible
        }
        
        var currentIndex = visibleIndex + 1;
        
        if childrenCount > 0 {
            for i in 1...childrenCount {
                let currentComment = comments[commentIndex + i]
                
                if visible && currentComment.Visibility == CommentModel.VisibilityType.Hidden { continue }

                try! realm.write {
                    currentComment.Visibility = visible ? CommentModel.VisibilityType.Hidden : CommentModel.VisibilityType.Visible
                }

                modifiedIndexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex += 1
            }
        }
        
        return (modifiedIndexPaths, visible ? .Hidden : .Visible)
    }
    
    func indexOfComment(_ comment: CommentModel, source: [CommentModel]) -> Int? {
        for (index, value) in source.enumerated() {
            if comment.ID == value.ID { return index }
        }
        return nil
    }
    
    func countChildren(_ comment: CommentModel) -> Int {
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
