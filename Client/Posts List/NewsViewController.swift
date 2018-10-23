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

class NewsViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl!

    var notificationToken: NotificationToken? = nil

    var posts: Results<PostModel>?
    var postType: HNScraper.PostListPageName = .news
    
    private var peekedIndexPath: IndexPath?
    private var nextPageIdentifier: String?
    
    private var cancelFetch: (() -> Void)?

    private var notifiedPostID: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = Realm.live()
        self.posts = realm.objects(PostModel.self).filter("Type == %@", self.postType.rawValue)

        notificationToken = self.posts!.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            guard let view = self?.view else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                view.hideSkeleton()
                tableView.rowHeight = UITableView.automaticDimension
                tableView.estimatedRowHeight = UITableView.automaticDimension
                tableView.reloadData()
                tableView.refreshControl?.endRefreshing()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()

                view.hideSkeleton()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }

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

        tabBarController?.tabBar.isHidden = false
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
        _ = HNUpdateManager.shared.loadPostsForType(self.postType).done { newPosts in
            print("Done and got new posts:", newPosts.count)
            self.view.hideSkeleton()
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = UITableView.automaticDimension
            self.tableView.refreshControl?.endRefreshing()
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
        if post.Type == HNPost.PostType.jobs.rawValue { // Job posts don't have comments, so lets go straight to the link
            if let vc = UserDefaults.standard.openInBrowser(post.LinkURL) {
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
        if indexPath.row == posts!.count - 5 {
            _ = HNUpdateManager.shared.loadMorePosts(self.postType)
        }
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
        if let safariViewController = UserDefaults.standard.openInBrowser(post.LinkURL) {
            safariViewController.onDoneBlock = { _ in
                self.userActivity = nil
            }

            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        let indexPath = self.peekedIndexPath!
        let post = posts![indexPath.row]
        let commentsPreviewActionTitle = post.Comments.count > 0 ? "View \(post.Comments.count) comments" : "View comments"
        
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
        activity.title = post.Title
        self.userActivity = activity

        let vc = UserDefaults.standard.openInBrowser(post.LinkURL)
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
}
