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
import RealmSwift
import FontAwesome_swift
import PromiseKit

class CommentsViewController : UIViewController {
    var post: HNPost? {
        didSet {
            setupPostTitleView()
            loadComments()

            // FIXME: Mark as read
            //self.post?.MarkAsRead()

            let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.comments")
            activity.isEligibleForHandoff = true
            activity.title = self.post?.ItemPageTitle
            activity.webpageURL = self.post?.ItemURL
            self.userActivity = activity
        }
    }

    var comments: [HNComment]? {
        didSet {
            if let comments = comments {
                commentsController.comments = comments
            }
        }
    }
    
    let commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var postTitleContainerView: UIView!
    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    var replyToComment: HNComment?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        setupPostTitleView()
        view.showAnimatedSkeleton(usingColor: AppThemeProvider.shared.currentTheme.skeletonColor)
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

        guard let post = self.post else { return }
        _ = HNRealtime.shared.Unmonitor(post.ID)
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
        guard let post = self.post else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            HNScraper.shared.GetChildren(post.ID).done {
                self.comments = $0 as? [HNComment]

                self.view.hideSkeleton()
                self.tableView.rowHeight = UITableView.automaticDimension
                self.tableView.reloadData()

                }.catch { error in
                    print("Got error while loading comments!", error)
            }
        }
    }
    
    func setupPostTitleView() {
        guard let postTitleView = postTitleView else { return }

        postTitleView.delegate = self
        postTitleView.isTitleTapEnabled = true

        guard let post = post else { return }
        
        postTitleView.post = post
        thumbnailImageView.setImage(post)
    }
    
    @IBAction func didTapThumbnail(_ sender: Any) {
        didPressLinkButton(post!)
    }
    
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        print("share tapped", self, self.navigationController, self.navigationController?.topViewController)

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

    @IBAction func moreButton(_ sender: UIBarButtonItem) {

    }

    @IBAction func sortButton(_ sender: UIBarButtonItem) {

    }

    @IBAction func replyButton(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "Reply", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Reply", let replyVC = segue.destination as? ReplyViewController {
            if let comment = self.replyToComment {
                replyVC.replyingTo = comment
                self.replyToComment = nil
            } else {
                replyVC.replyingTo = self.post
            }
        }
    }

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

    override var keyCommands: [UIKeyCommand] {
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

        // Only logged in users can swipe to upvote/downvote
        guard UserDefaults.standard.loggedInUser != nil else { return nil }

        let comment = commentsController.visibleComments[indexPath.row]

        let actions = comment.Actions != nil ? comment.Actions! : HNScraper.shared.ActionsCache[comment.ID]!

        return actions.swipeActionsConfiguration(item: comment, trailing: false)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Only logged in users can swipe to upvote/downvote
        guard UserDefaults.standard.loggedInUser != nil else { return nil }

        let comment = commentsController.visibleComments[indexPath.row]

        let actions = comment.Actions != nil ? comment.Actions! : HNScraper.shared.ActionsCache[comment.ID]!

        let config = actions.swipeActionsConfiguration(item: comment, trailing: true)

        let replyAction = UIContextualAction(style: UIContextualAction.Style.normal, title: "Reply") { (_, _, complete) in
            self.replyToComment = comment
            self.performSegue(withIdentifier: "Reply", sender: self)
            complete(true)
        }

        return UISwipeActionsConfiguration(actions: config.actions + [replyAction])
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
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

        tableView.performBatchUpdates({
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            if visibility == HNItem.ItemVisibilityType.Hidden {
                self.tableView.deleteRows(at: modifiedIndexPaths, with: .top)
            } else {
                self.tableView.insertRows(at: modifiedIndexPaths, with: .top)
            }
        }) { (finished) in
            let cellRectInTableView = self.tableView.rectForRow(at: indexPath)
            let cellRectInSuperview = self.tableView.convert(cellRectInTableView, to: self.tableView.superview)
            if cellRectInSuperview.origin.y < 0 {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
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
