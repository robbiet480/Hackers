//
//  SearchViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/4/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import InstantSearchClient
import MoreCodable

class SearchViewController: UIViewController {

    let client = Client(appID: "UJ5WYC0L7X", apiKey: "8ece23f8eb07cd25d40262a1764599b1")

    var searchIndex: Index?

    var posts: [HNPost]?
    var users: [HNUser]?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTypeControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!

    private var selectedUser: HNUser?

    @IBAction func searchTypeChanged(_ sender: UISegmentedControl) {
        print("Search type changed to", self.searchTypeControl.selectedSegmentIndex)

        if self.searchTypeControl.selectedSegmentIndex == 0 {
            self.searchIndex = client.index(withName: "Item_production")
        } else if self.searchTypeControl.selectedSegmentIndex == 1 {
            self.searchIndex = client.index(withName: "User_production")
        }

        self.searchBar.text = nil
        self.searchBar.endEditing(true)

        self.posts = nil
        self.users = nil

        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        self.tableView.delegate = self
        self.tableView.dataSource = self

        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "PostCell")

        self.searchIndex = client.index(withName: "Item_production")

        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap(sender:)))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.isEnabled = true
        singleTapGestureRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(singleTapGestureRecognizer)
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

    @objc func singleTap(sender: UITapGestureRecognizer) {
        self.searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchTypeControl.selectedSegmentIndex == 0 {
            return self.posts?.count ?? 0
        }

        return self.users?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if self.searchTypeControl.selectedSegmentIndex == 0, let posts = self.posts {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            cell.tag = indexPath.row
            cell.delegate = self
            cell.clearImage()

            let post = posts[indexPath.row]

            cell.post = post
            cell.postTitleView.post = post
            cell.postTitleView.delegate = self

            cell.thumbnailImageView.setImage(post)

            return cell
        } else if let users = self.users {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)

            let user = users[indexPath.row]

            cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

            cell.textLabel?.text = user.Username
            cell.textLabel?.textColor = AppThemeProvider.shared.currentTheme.textColor

            cell.detailTextLabel?.text = String(user.Karma)
            cell.detailTextLabel?.textColor = AppThemeProvider.shared.currentTheme.textColor

            return cell
        }

        return tableView.dequeueReusableCell(withIdentifier: "InvalidCell", for: indexPath)
    }

}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.searchTypeControl.selectedSegmentIndex == 0, let posts = self.posts {
            let post = posts[indexPath.row]
            if post.Type == .job { // Job posts don't have comments, so lets go straight to the link
                if let link = post.Link, let vc = OpenInBrowser.shared.openURL(link) {
                    self.present(vc, animated: true, completion: nil)
                }
            } else {
                self.performSegue(withIdentifier: "ShowComments", sender: self)
            }

            self.tableView.deselectRow(at: indexPath, animated: true)
            return
        } else if let users = self.users {
            self.selectedUser = users[indexPath.row]
            self.performSegue(withIdentifier: "Profile", sender: self)

            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension SearchViewController: PostCellDelegate {
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

extension SearchViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        let activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
        activity.isEligibleForHandoff = true
        activity.webpageURL = post.Link
        activity.title = post.Title
        self.userActivity = activity

        if let link = post.Link, let vc = OpenInBrowser.shared.openURL(link) {
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
        self.show(self.getNewsVC(HNScraper.Page.Site(domainName: domainName)), sender: self)
    }

    func getNewsVC(_ postType: HNScraper.Page) -> UIViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
        guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
        guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

        newsVC.title = postType.description

        newsVC.postType = postType

        newsVC.hideBarItems = true

        return newsVC
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchIndex!.search(Query(query: searchText), completionHandler: { (content, error) -> Void in
            if let error = error {
                print("Error during Algolia search:", error)
            } else if let content = content {
                let decoder = ISO8601DictionaryDecoder()

                do {
                    if self.searchTypeControl.selectedSegmentIndex == 0 {
                        let casted = try decoder.decode(AlgoliaItemsSearchResult.self, from: content)
                        self.posts = casted.hits.map { $0.hnItem }
                    } else if self.searchTypeControl.selectedSegmentIndex == 1 {
                        let casted = try decoder.decode(AlgoliaUsersSearchResult.self, from: content)
                        self.users = casted.hits.map { $0.hnUser }
                    }
                } catch let error as NSError {
                    print("Got error during decode", content, error)
                }

                self.tableView.reloadData()
            }
        })
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        searchBar.tintColor = theme.appTintColor
        searchBar.backgroundColor = theme.barBackgroundColor
    }
}
