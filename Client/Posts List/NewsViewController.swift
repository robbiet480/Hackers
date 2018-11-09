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
import FontAwesome_swift
import PromiseKit

class NewsViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken? = nil

    var posts: [HNPost]?
    var pageType: HNScraper.Page = .Home
    var pageNumber: Int = 1

    private var peekedIndexPath: IndexPath?
    private var nextPageIdentifier: String?
    
    private var cancelFetch: (() -> Void)?

    @IBOutlet weak var composeButton: UIBarButtonItem!

    private var selectedUser: HNUser?

    public var hideBarItems: Bool = false {
        didSet {
            if hideBarItems == true {
                self.navigationItem.leftBarButtonItems = nil
                self.navigationItem.rightBarButtonItems = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadPosts()

        registerForPreviewing(with: self, sourceView: tableView)

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NewsViewController.loadPosts), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        setupTheming()

        view.showAnimatedSkeleton(usingColor: AppThemeProvider.shared.currentTheme.skeletonColor)

        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "PostCell")

        if !self.hideBarItems, case .ForDate = self.pageType {
            let fakIcon = UIImage.fontAwesomeIcon(name: FontAwesome.calendarAlt, style: FontAwesomeStyle.regular,
                                                  textColor: AppThemeProvider.shared.currentTheme.appTintColor, size: CGSize(width: 30, height: 30))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: fakIcon, style: .plain, target: self, action: nil)

            self.pageType = .ForDate(date: Date(timeIntervalSince1970: 1465171200))

            self.navigationItem.title = self.pageType.description

            self.loadPosts()
        }
    }

    @IBAction func composePressed(_ sender: UIBarButtonItem) {
        if UserDefaults.standard.loggedInUser == nil {
            let alertController = UIAlertController(title: "Not logged in", message: "You must be logged in to do that", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }

        self.performSegue(withIdentifier: "Compose", sender: self)
    }

    @IBAction func changeTheme(_ sender: Any) {
        AppThemeProvider.shared.nextTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rz_smoothlyDeselectRows(tableView: tableView)
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

    public convenience init(_ postType: HNScraper.Page) {
        self.init()

        self.pageType = postType
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowComments", let indexPath = tableView.indexPathForSelectedRow,
            let commentsViewController = segue.destination as? CommentsViewController {

            let post = posts![indexPath.row]
            commentsViewController.post = post
        } else if segue.identifier == "Profile", let vc = segue.destination as? ProfileViewController {
            vc.user = self.selectedUser
            self.selectedUser = nil
        }
    }

    @objc func loadPosts() {
        _ = HNScraper.shared.GetPage(self.pageType).done { newPosts in
            guard let newPosts = newPosts as? [HNPost] else { return }
            print("Done getting \(self.pageType.description) posts and got \(newPosts.count) new ones")

            ImagePrefetcher(resources: newPosts.compactMap { $0.ThumbnailImageResource }).start()

            /*DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                let startTime = Date().timeIntervalSince1970

                print("Starting cache fill", startTime)

                HTMLDataSource().GetActions(self.pageType).done { _ in
                    print("Done filling actions cache, took", Date().timeIntervalSince1970 - startTime)
                }.catch { error in
                    print("Got error while filling actions cache!", error)
                }
            }*/

            if self.pageType != .Jobs && UserDefaults.standard.hideJobs {
                self.posts = newPosts.filter { $0.Type != .job }
            } else {
                self.posts = newPosts
            }

            self.view.hideSkeleton()
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
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

    override var keyCommands: [UIKeyCommand] {
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

        let post = posts![indexPath.row]
        cell.post = post

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts![indexPath.row]
        if post.Type == .job { // Job posts don't have comments, so lets go straight to the link
            if let link = post.Link, let vc = OpenInBrowser.shared.openURL(link) {
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            self.performSegue(withIdentifier: "ShowComments", sender: self)
        }
    }
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard posts != nil else { return }

        if indexPath.row == posts!.count - 5 {
            print("Getting next page of stories!", indexPath.row, posts!.count)

            self.pageNumber += 1

            _ = HNScraper.shared.GetPage(self.pageType, pageNumber: self.pageNumber).done { newPosts in
                guard let newPosts = newPosts as? [HNPost] else { return }
                print("Done getting \(self.pageType.description) posts and got \(newPosts.count) new ones")

                ImagePrefetcher(resources: newPosts.compactMap { $0.ThumbnailImageResource }).start()

                self.posts!.append(contentsOf: newPosts)

                self.tableView.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

            // Only logged in users can swipe to upvote/downvote
            guard UserDefaults.standard.loggedInUser != nil else { print("Not logged in!"); return nil }

            let post = posts![indexPath.row]

            guard let actions = post.Actions != nil ? post.Actions! : HNScraper.shared.ActionsCache[post.ID] else { return nil }

            let config = actions.swipeActionsConfiguration(item: post, trailing: false)

            return config
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Only logged in users can swipe to upvote/downvote
        guard UserDefaults.standard.loggedInUser != nil else { return nil }

        let post = posts![indexPath.row]

        guard let actions = post.Actions != nil ? post.Actions! : HNScraper.shared.ActionsCache[post.ID] else { return nil }

        return actions.swipeActionsConfiguration(item: post, trailing: true)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let posts = self.posts, posts.count > indexPath.row {
            let post = posts[indexPath.row]
            _ = HNRealtime.shared.Unmonitor(post.ID)
        }

        if let cell = cell as? PostCell, let view = cell.previewImageView {
            view.kf.cancelDownloadTask()
        }
    }
}

extension NewsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        refreshControl.tintColor = theme.appTintColor
        self.tableView.reloadData()
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
        peekedIndexPath = indexPath
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        guard let link = post.Link else { return nil }
        let safariViewController = ThemedSafariViewController(url: link)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        let post = posts![self.peekedIndexPath!.row]
        if let link = post.Link, let safariViewController = OpenInBrowser.shared.openURL(link) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }

    }
    
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        let indexPath = self.peekedIndexPath!
        let post = posts![indexPath.row]
        let commentsPreviewActionTitle = post.TotalChildren > 0 ? "View \(post.TotalChildren) comments" : "View comments"
        
        let viewCommentsPreviewAction = UIPreviewAction(title: commentsPreviewActionTitle, style: .default) {
            [unowned self, indexPath = indexPath] (action, viewController) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.performSegue(withIdentifier: "ShowComments", sender: nil)
        }
        return [viewCommentsPreviewAction]
    }
}

extension NewsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = post.Link
        activity.title = post.Title
        self.userActivity = activity

        if let link = post.Link, let vc = OpenInBrowser.shared.openURL(link) {
            vc.previewActionItemsDelegate = self

            vc.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.navigationController?.present(vc, animated: true, completion: nil)
        }
    }

    func didTapUsername(_ user: HNUser) {
        self.selectedUser = user
        self.performSegue(withIdentifier: "Profile", sender: self)
    }

    func didTapDomain(_ domainName: String) {
        print("Tapped domain", domainName)
        self.show(self.getNewsVC(HNScraper.Page.Site(domainName: domainName)), sender: self)
    }

    func getNewsVC(_ postType: HNScraper.Page) -> UIViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
        guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
        guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

        newsVC.title = postType.description

        newsVC.pageType = postType

        newsVC.hideBarItems = true

        return newsVC
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
