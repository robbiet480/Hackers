//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import SkeletonView
import Kingfisher
import RealmSwift
import HNScraper
import FirebaseDatabase
import FontAwesome_swift
import PromiseKit

class NewsViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken? = nil

    var posts: [PostModel]?
    var postType: HNScraper.PostListPageName = .news
    
    private var peekedIndexPath: IndexPath?
    private var nextPageIdentifier: String?
    
    private var cancelFetch: (() -> Void)?

    private var notifiedPostID: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadPosts()

        registerForPreviewing(with: self, sourceView: tableView)

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        
        setupTheming()
        
        view.showAnimatedSkeleton(usingColor: AppThemeProvider.shared.currentTheme.skeletonColor)

        NotificationCenter.default.addObserver(self, selector: #selector(NewsViewController.openPostNotification(_:)), name: NSNotification.Name(rawValue: "notificationOpenPost"), object: nil)
    }
    
    @IBAction func changeTheme(_ sender: Any) {
        AppThemeProvider.shared.nextTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rz_smoothlyDeselectRows(tableView: tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UIDevice().userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = false
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.global().async(execute: {
            DispatchQueue.main.sync {
                self.viewDidRotate()
            }
        })
    }

    public func viewDidRotate() {
        guard let tableView = self.tableView, let indexPaths = tableView.indexPathsForVisibleRows else { return }
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: indexPaths, with: .automatic)
        self.tableView.endUpdates()
    }

    @objc func openPostNotification(_ notification: Notification) {
        print("Received notification!", notification)

        if let postID = notification.userInfo?["POST_ID"] as? Int {
            print("Open post id!")

            self.notifiedPostID = postID

            self.performSegue(withIdentifier: "ShowComments", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowComments" {
            if let notifiedPostID = self.notifiedPostID, let segueNavigationController = segue.destination as? UINavigationController,
                let commentsViewController = segueNavigationController.topViewController as? CommentsViewController {

                self.notifiedPostID = nil

                let realm = Realm.live()
                let post = realm.object(ofType: PostModel.self, forPrimaryKey: notifiedPostID)
                commentsViewController.post = post
            } else if let indexPath = tableView.indexPathForSelectedRow,
                let segueNavigationController = segue.destination as? UINavigationController,
                let commentsViewController = segueNavigationController.topViewController as? CommentsViewController {
        
                let post = posts![indexPath.row]
                commentsViewController.post = post
            }
        }
    }

    @objc func loadPosts() {
        _ = HNFirebaseClient.shared.getStoriesForPage(self.postType, limit: 30).done { newPosts in
            print("Done getting \(self.postType.description) posts and got \(newPosts.count) new ones")

            self.posts = newPosts

            self.view.hideSkeleton()
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = UITableView.automaticDimension
            self.tableView.reloadData()
        }
    }

}

extension NewsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let posts = self.posts {
            return posts.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        cell.tag = indexPath.row
        cell.delegate = self
        cell.clearImage()

        let post = posts![indexPath.row]
        cell.post = post
        cell.postTitleView.post = post
        cell.postTitleView.delegate = self

        cell.thumbnailImageView.setImage(post)
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts![indexPath.row]
        if post.type == .job { // Job posts don't have comments, so lets go straight to the link
            if let vc = OpenInBrowser.shared.openURL(post.LinkURL) {
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            self.performSegue(withIdentifier: "ShowComments", sender: self)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCell {
            cell.thumbnailImageView.kf.cancelDownloadTask()
        }
    }
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard posts != nil else { return }

        if indexPath.row == posts!.count - 5 {
            print("Getting stories!", indexPath.row, posts!.count)
            _ = HNFirebaseClient.shared.getStoriesForPage(self.postType)
        }
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

            // Only logged in users can swipe to upvote/downvote
            guard UserDefaults.standard.loggedInUser != nil else { return nil }

            let post = posts![indexPath.row]

            // Post was already voted on
            guard post.VotedAt == nil else { return nil }

            let action = UIContextualAction(style: .normal, title: "Upvote", handler: { (action, view, completionHandler) in

                let postID = post.ID

                DispatchQueue.global(qos: .userInitiated).async {
                    _ = HNScraper.shared.voteItem(postID, action: .Upvote).done { authKey in
                        let realm = Realm.live()

                        let post = realm.object(ofType: PostModel.self, forPrimaryKey: postID)

                        try! realm.write {
                            post?.VotedAt = Date()
                            post?.Upvoted.value = true
                            post?.VoteKey = authKey
                        }
                    }
                }

                completionHandler(false)
            })

            action.backgroundColor = .orange
            action.image = UIImage.fontAwesomeIcon(name: .arrowUp, style: .solid,
                                                   textColor: .white, size: CGSize(width: 36, height: 36))

            return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
}

extension NewsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        refreshControl.tintColor = theme.appTintColor
    }
}

extension NewsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
    }
}

extension NewsViewController: UIViewControllerPreviewingDelegate, SFSafariViewControllerPreviewActionItemsDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), posts!.count > indexPath.row else { return nil }
        let post = posts![indexPath.row]
        if verifyLink(post.LinkURL.description) {
            peekedIndexPath = indexPath
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            let safariViewController = ThemedSafariViewController(url: post.LinkURL)
            safariViewController.previewActionItemsDelegate = self
            return safariViewController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        let post = posts![self.peekedIndexPath!.row]
        if let safariViewController = OpenInBrowser.shared.openURL(post.LinkURL) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        let indexPath = self.peekedIndexPath!
        let post = posts![indexPath.row]
        let commentsPreviewActionTitle = post.descendants > 0 ? "View \(post.descendants) comments" : "View comments"
        
        let viewCommentsPreviewAction = UIPreviewAction(title: commentsPreviewActionTitle, style: .default) {
            [unowned self, indexPath = indexPath] (action, viewController) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.performSegue(withIdentifier: "ShowComments", sender: nil)
        }
        return [viewCommentsPreviewAction]
    }
}

extension NewsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: PostModel) {
        guard verifyLink(post.URLString) else { return }
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = post.LinkURL
        activity.title = post.title
        self.userActivity = activity

        let vc = OpenInBrowser.shared.openURL(post.LinkURL)
        if let vc = vc {
            vc.previewActionItemsDelegate = self

            vc.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.navigationController?.present(vc, animated: true, completion: nil)
        }
    }

    func verifyLink(_ urlString: String?) -> Bool {
        guard let urlString = urlString, let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

extension NewsViewController: PostCellDelegate {
    func didTapThumbnail(_ sender: Any) {
        guard let tapGestureRecognizer = sender as? UITapGestureRecognizer else { return }
        let point = tapGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts![indexPath.row]
            didPressLinkButton(post)
        }
    }

    func didLongPressCell(_ sender: Any) {
        guard let longPressGestureRecognizer = sender as? UILongPressGestureRecognizer else { return }
        let point = longPressGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts![indexPath.row]

            let alertController = UIAlertController(title: "Share...", message: nil, preferredStyle: .actionSheet)
            let postURLAction = UIAlertAction(title: "Content Link", style: .default) { action in
                let linkVC = post.LinkActivityViewController
                UIApplication.shared.keyWindow?.rootViewController?.present(linkVC, animated: true, completion: nil)
                linkVC.popoverPresentationController?.sourceView = self.tableView
                linkVC.popoverPresentationController?.sourceRect = self.tableView.cellForRow(at: indexPath)!.frame
            }
            let hackerNewsURLAction = UIAlertAction(title: "Hacker News Link", style: .default) { action in
                let commentsVC = post.CommentsActivityViewController
                UIApplication.shared.keyWindow?.rootViewController?.present(commentsVC, animated: true, completion: nil)
                commentsVC.popoverPresentationController?.sourceView = self.tableView
                commentsVC.popoverPresentationController?.sourceRect = self.tableView.cellForRow(at: indexPath)!.frame
            }
            alertController.addAction(postURLAction)
            alertController.addAction(hackerNewsURLAction)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            UIApplication.shared.keyWindow?.rootViewController?.present(alertController,
                                                                        animated: true, completion: nil)

            alertController.popoverPresentationController?.sourceView = self.tableView
            alertController.popoverPresentationController?.sourceRect = self.tableView.cellForRow(at: indexPath)!.frame
        }
    }
}

extension NewsViewController: KeyCommandProvider {
    @objc func handleShortcut(keyCommand: UIKeyCommand) -> Bool {
        // Why j/k? https://www.labnol.org/internet/j-k-keyboard-shortcuts/20779/
        if keyCommand.input == "j" {
            selectPrev(sender: keyCommand)
            return true
        } else if keyCommand.input == "k" {
            selectNext(sender: keyCommand)
            return true
        } else if keyCommand.input == "r" {
            // https://stackoverflow.com/a/50551396/486182
            refreshControl.beginRefreshing()
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - (refreshControl.frame.size.height)),
                                       animated: true)
            self.loadPosts()
            return true
        } else if keyCommand.input == "\r" {
            selectCurrent(sender: keyCommand)
            return true
        } else if keyCommand.input == "l" {
            openLink(sender: keyCommand)
            return true
        }

        return false
    }

    // UITableView keyboard shortcuts found at
    // https://stablekernel.com/creating-a-delightful-user-experience-with-ios-keyboard-shortcuts/

    var shortcutKeys: [UIKeyCommand] {
        let reloadCommand = UIKeyCommand(input: "r", modifierFlags: .command,
                                         action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Reload")
        let previousObjectCommand = UIKeyCommand(input: "j", modifierFlags: .shift,
                                                 action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Previous Story")
        let nextObjectCommand = UIKeyCommand(input: "k", modifierFlags: .shift,
                                             action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Next Story")
        let selectObjectCommand = UIKeyCommand(input: "\r", modifierFlags: .shift,
                                               action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Open Story Comments")
        let openLinkCommand = UIKeyCommand(input: "l", modifierFlags: [],
                                           action: #selector(handleShortcut(keyCommand:)), discoverabilityTitle: "Open Story Link")

        var shortcuts: [UIKeyCommand] = [reloadCommand]
        if let selectedRow = self.tableView?.indexPathForSelectedRow?.row {
            if selectedRow < self.posts!.count - 1 {
                shortcuts.append(nextObjectCommand)
            }
            if selectedRow > 0 {
                shortcuts.append(previousObjectCommand)
            }
            shortcuts.append(contentsOf: [selectObjectCommand, openLinkCommand])
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
        self.performSegue(withIdentifier: "ShowComments", sender: self)
    }

    @objc func openLink(sender: UIKeyCommand) {
        if let selectedIP = self.tableView?.indexPathForSelectedRow {
            didPressLinkButton(posts![selectedIP.row])
        }
    }
}
