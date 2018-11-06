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
            guard let post = self.post else { return }

            setupPostTitleView()

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

    var openedFromNotification: Bool = false

    var notifAction: NotificationActions?

    let commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var postTitleContainerView: UIView!
    @IBOutlet weak var postTitleView: CommentsPostTitleView!

    var replyToComment: HNComment?

    var selectedUser: HNUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        setupPostTitleView()
        view.showAnimatedSkeleton(usingColor: AppThemeProvider.shared.currentTheme.skeletonColor)

        if self.openedFromNotification {
            let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone(_:)))
            self.navigationItem.rightBarButtonItems?.insert(barButton, at: 0)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.openedFromNotification, let post = self.post {
            // If user hit "Open Link" action
            // OR
            // User tapped notification AND has the notification tap opens link preference set
            // OR
            // Post type is job, since job posts don't have comments, so lets go directly to the link
            if (self.notifAction == .OpenLink || (self.notifAction == .DefaultTap && UserDefaults.standard.notificationTapOpensLink) || post.Type == .job),
                let link = post.Link {

                let vc = OpenInBrowser.shared.openURL(link)

                if let vc = vc { // We are opening a SFSafariViewController.
                    vc.onDoneBlock = { _ in
                        self.dismiss(animated: true, completion: nil)
                    }

                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }

            } else if let action = notifAction {
                var shareVC: UIActivityViewController?
                switch action {
                case .ShareComments:
                    shareVC = post.CommentsActivityViewController
                case .ShareLink:
                    shareVC = post.LinkActivityViewController
                default: break
                }

                if let shareVC = shareVC {
                    shareVC.modalPresentationStyle = .fullScreen
                    shareVC.completionWithItemsHandler = {(_, _, _, _) in
                        self.dismiss(animated: true, completion: nil)
                    }
                    self.present(shareVC, animated: true, completion: nil)
                }
            }
        }

        self.loadComments()
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

    @objc func handleDone(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    func loadComments() {
        guard let post = self.post else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            HNScraper.shared.GetItem(post.ID).done { item in
                self.comments = item?.Children

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

        guard let post = post else { return }
        
        postTitleView.post = post
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
        } else if segue.identifier == "Profile", let profileVC = segue.destination as? ProfileViewController {
            profileVC.user = self.selectedUser
            self.selectedUser = nil
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

extension CommentsViewController: CommentsPostTitleViewDelegate {
    func didPressLinkButton() {
        // animate background colour for tap
        self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
        })

        // show link
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = self.post!.Link
        activity.title = self.post!.Title
        self.userActivity = activity

        if let link = post!.Link, let safariViewController = OpenInBrowser.shared.openURL(link) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }
    }

    func didPressActionButton(_ action: ActionButton, _ sender: UIBarButtonItem) -> Bool {
        guard let post = self.post else { return false }

        switch action {
        case .Vote:
            print("Vote hit")
            if let actions = post.Actions {
                if let unvote = actions.Unvote {
                    _ = post.FireAction(unvote)
                    return true
                } else if let upvote = actions.Upvote {
                    _ = post.FireAction(upvote)
                    return true
                } else if let downvote = actions.Downvote {
                    _ = post.FireAction(downvote)
                    return true
                }
            }
            return true
        case .Favorite:
            print("Favorite hit")
            if let actions = post.Actions {
                if let fave = actions.Favorite {
                    _ = post.FireAction(fave)
                    return true
                } else if let unfave = actions.Unfavorite {
                    _ = post.FireAction(unfave)
                    return true
                }
            }
            return true
        case .Flag:
            print("Flag hit")
            if let actions = post.Actions {
                if let flag = actions.Flag {
                    _ = post.FireAction(flag)
                    return true
                } else if let unflag = actions.Unflag {
                    _ = post.FireAction(unflag)
                    return true
                }
            }
            return true
        case .Reply:
            print("Reply hit")
            self.performSegue(withIdentifier: "Reply", sender: self)
            return true
        case .Share:
            print("Share hit")
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
            return true
        }
    }

    func didTapAuthorLabel() {
        print("Author hit, open author view for", post!.Author!)
        self.selectedUser = self.post?.Author
        self.performSegue(withIdentifier: "Profile", sender: self)
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

    func authorTapped(_ user: HNUser) {
        self.selectedUser = user
        self.performSegue(withIdentifier: "Profile", sender: self)
    }
}

extension CommentsViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSAttributedString.Key.font: UIFont.mySystemFont(ofSize: 15.0)]
        return comments == nil ? NSAttributedString(string: "Loading comments", attributes: attributes) : NSAttributedString(string: "No comments", attributes: attributes)
    }
}

extension CommentsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
    }
}
