//
//  CommentsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import DZNEmptyDataSet
import SkeletonView
import FirebaseDatabase
import RealmSwift
import FontAwesome_swift
import PromiseKit

class CommentsViewController : UIViewController {
    var post: HNPost?

    var comments: [HNItem]? {
        didSet { commentsController.comments = comments! }
    }
    
    let commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var postTitleContainerView: UIView!
    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        setupPostTitleView()
        view.showAnimatedSkeleton(usingColor: AppThemeProvider.shared.currentTheme.skeletonColor)
        loadComments()

        // FIXME: Mark as read
        //self.post?.MarkAsRead()

        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.comments")
        activity.isEligibleForHandoff = true
        // FIXME: Needs the correct comment title
        activity.title = self.post!.ItemPageTitle
        activity.webpageURL = self.post!.ItemURL
        self.userActivity = activity
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice().userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.userActivity?.resignCurrent()
        self.userActivity = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            // If we don't have this check, viewDidLayoutSubviews() will get called infinitely
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    func loadComments() {
        HNScraper.shared.GetChildren(self.post!.ID).done {
            print("Got comments", $0)
            self.comments = $0

            self.view.hideSkeleton()
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.reloadData()

        }.catch { error in
            print("Got error while loading comments!", error)
        }
    }
    
    func setupPostTitleView() {
        guard let post = post else { return }
        
        postTitleView.post = post
        postTitleView.delegate = self
        postTitleView.isTitleTapEnabled = true
        thumbnailImageView.setImage(post)
    }
    
    @IBAction func didTapThumbnail(_ sender: Any) {
        didPressLinkButton(post!)
    }
    
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Share...", message: nil, preferredStyle: .actionSheet)
        let postURLAction = UIAlertAction(title: "Content Link", style: .default) { action in
            let linkVC = self.post!.LinkActivityViewController
            linkVC.popoverPresentationController?.barButtonItem = sender
            self.present(linkVC, animated: true, completion: nil)
        }
        let hackerNewsURLAction = UIAlertAction(title: "Hacker News Link", style: .default) { action in
            let commentsVC = self.post!.CommentsActivityViewController
            commentsVC.popoverPresentationController?.barButtonItem = sender
            self.present(commentsVC, animated: true, completion: nil)
        }
        alertController.addAction(postURLAction)
        alertController.addAction(hackerNewsURLAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        self.present(alertController, animated: true, completion: nil)

        alertController.popoverPresentationController?.barButtonItem = sender
    }
}

extension CommentsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        // animate background colour for tap
        self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
        })

        // show link
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = post.Link
        activity.title = post.Title
        self.userActivity = activity

        if let link = post.Link, let safariViewController = OpenInBrowser.shared.openURL(link) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func verifyLink(_ urlString: String?) -> Bool {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
}

extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsController.visibleComments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = commentsController.visibleComments[indexPath.row]
        assert(comment.Visibility != HNItem.ItemVisibilityType.Hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.Visibility == HNItem.ItemVisibilityType.Visible ? "OpenCommentCell" : "ClosedCommentCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CommentTableViewCell

        cell.post = post
        cell.comment = comment
        cell.delegate = self
        
        return cell
    }
}

extension CommentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("CommentsHeader", owner: nil, options: nil)?.first as? UIView
        return view
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let comment = commentsController.visibleComments[indexPath.row]

        print("post?.ChildActions[comment.ID]?.Upvote", post?.AllActions)

        return self.runItemAction(indexPath, post?.AllActions[comment.ID]?.Upvote)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let comment = commentsController.visibleComments[indexPath.row]

        var action: HNItem.ActionType? = post?.AllActions[comment.ID]?.Downvote

        if comment.Upvoted != nil && Date().isBeforeDate(comment.VotedAt!.addingTimeInterval(3600), granularity: .minute) {
            action = post?.AllActions[comment.ID]?.Unvote
        }

        return self.runItemAction(indexPath, action)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func runItemAction(_ indexPath: IndexPath, _ action: HNItem.ActionType?) -> UISwipeActionsConfiguration? {

        guard let action = action else { return nil }

        // Only logged in users can swipe to upvote/downvote
        guard UserDefaults.standard.loggedInUser != nil else { return nil }

        let comment = commentsController.visibleComments[indexPath.row]

        // comment was already voted on
        // FIXME: Ensure that users can't double vote
        // guard voteAction != .Unvote && comment.VotedAt == nil else { return nil }

        var title = ""
        var color: UIColor = .clear
        var faIcon: FontAwesome = .arrowUp

        switch action {
        case .Favorite:
            title = "Favorite"
            color = .yellow
            faIcon = .star
        case .Flag:
            title = "flag"
            color = .orange
            faIcon = .flag
        case .Unvote:
            title = "Unvote"
            color = .red
            faIcon = .times
        case .Vote(_, _, let direction):
            switch direction {
            case .Up:
                title = "Upvote"
                color = .orange
                faIcon = .arrowUp
            case .Down:
                title = "Downvote"
                color = .blue
                faIcon = .arrowDown
            }
        default:
            print("Not handling", action)
        }

        let tableAction = UIContextualAction(style: .normal, title: title, handler: { (action, view, completionHandler) in

            let commentID = comment.ID

            // FIXME: Actually vote

//            DispatchQueue.global(qos: .userInitiated).async {
//                _ = HNScraper.shared.voteItem(commentID, action: voteAction).done { authKey in
//                    let realm = Realm.live()
//
//                    let comment = realm.object(ofType: CommentModel.self, forPrimaryKey: commentID)
//
//                    try! realm.write {
//                        switch voteAction {
//                        case .Upvote, .Downvote:
//                            comment?.VotedAt = Date()
//                            comment?.Upvoted.value = (voteAction == .Upvote)
//                            comment?.VoteKey = authKey
//                        case .Unvote:
//                            comment?.VotedAt = nil
//                            comment?.Upvoted.value = nil
//                            comment?.VoteKey = authKey
//                        }
//                    }
//                }
//            }

            completionHandler(false)
        })

        tableAction.backgroundColor = color
        tableAction.image = UIImage.fontAwesomeIcon(name: faIcon, style: .solid, textColor: .white,
                                                    size: CGSize(width: 36, height: 36))

        return UISwipeActionsConfiguration(actions: [tableAction])
    }
}

extension CommentsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        postTitleContainerView.backgroundColor = theme.backgroundColor
    }
}

extension CommentsViewController: CommentDelegate {
    func commentLongPressed(_ sender: UITableViewCell) {

        guard let indexPath = tableView.indexPath(for: sender) else { return }
        guard commentsController.comments.count > indexPath.row else { return }
        let comment = commentsController.comments[indexPath.row]

        let activityVC = comment.CommentsActivityViewController

        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: nil)

        activityVC.popoverPresentationController?.sourceView = self.tableView
        activityVC.popoverPresentationController?.sourceRect = self.tableView.cellForRow(at: indexPath)!.frame
    }

    func commentTapped(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            toggleCellVisibilityForCell(indexPath)
        }
    }
    
    func linkTapped(_ URL: Foundation.URL, sender: UITextView) {
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = URL
        activity.title = post!.Title
        self.userActivity = activity

        if let safariViewController = OpenInBrowser.shared.openURL(URL) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func toggleCellVisibilityForCell(_ indexPath: IndexPath!) {
        guard commentsController.visibleComments.count > indexPath.row else { return }
        let comment = commentsController.visibleComments[indexPath.row]
        let (modifiedIndexPaths, visibility) = commentsController.toggleCommentChildrenVisibility(comment)
        
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .fade)
        if visibility == HNItem.ItemVisibilityType.Hidden {
            tableView.deleteRows(at: modifiedIndexPaths, with: .top)
        } else {
            tableView.insertRows(at: modifiedIndexPaths, with: .top)
        }
        tableView.endUpdates()
        
        let cellRectInTableView = tableView.rectForRow(at: indexPath)
        let cellRectInSuperview = tableView.convert(cellRectInTableView, to: tableView.superview)
        if cellRectInSuperview.origin.y < 0 {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}

extension CommentsViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        return comments == nil ? NSAttributedString(string: "Loading comments", attributes: attributes) : NSAttributedString(string: "No comments", attributes: attributes)
    }
}

extension CommentsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
    }
}

extension CommentsViewController: KeyCommandProvider {
    @objc func handleShortcut(keyCommand: UIKeyCommand) -> Bool {
        // Why j/k? https://www.labnol.org/internet/j-k-keyboard-shortcuts/20779/
        if keyCommand.input == "j" {
            selectPrev(sender: keyCommand)
            return true
        } else if keyCommand.input == "k" {
            selectNext(sender: keyCommand)
            return true
        } else if keyCommand.input == "\r" {
            selectCurrent(sender: keyCommand)
            return true
        }

        return false
    }

    // UITableView keyboard shortcuts found at
    // https://stablekernel.com/creating-a-delightful-user-experience-with-ios-keyboard-shortcuts/

    var shortcutKeys: [UIKeyCommand] {
        let previousObjectCommand = UIKeyCommand(input: "j", modifierFlags: [],
                                                 action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Previous Comment")
        let nextObjectCommand = UIKeyCommand(input: "k", modifierFlags: [],
                                             action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Next Comment")
        let selectObjectCommand = UIKeyCommand(input: "\r", modifierFlags: [],
                                               action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Toggle Comment Visibility")

        var shortcuts: [UIKeyCommand] = []
        if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
            if selectedRow < self.comments!.count - 1 {
                shortcuts.append(nextObjectCommand)
            }
            if selectedRow > 0 {
                shortcuts.append(previousObjectCommand)
            }
            shortcuts.append(selectObjectCommand)
        } else {
            shortcuts.append(nextObjectCommand)
        }
        return shortcuts
    }

    @objc func selectNext(sender: UIKeyCommand) {
        if let selectedIP = self.tableView?.indexPathForSelectedRow {
            self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row + 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
        } else {
            self.tableView.selectRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, animated: true, scrollPosition: .top)
        }
    }

    @objc func selectPrev(sender: UIKeyCommand) {
        if let selectedIP = self.tableView?.indexPathForSelectedRow {
            self.tableView.selectRow(at: NSIndexPath(row: selectedIP.row - 1, section: selectedIP.section) as IndexPath, animated: true, scrollPosition: .middle)
        }
    }

    @objc func selectCurrent(sender: UIKeyCommand) {
        toggleCellVisibilityForCell(self.tableView.indexPathForSelectedRow)
    }
}
