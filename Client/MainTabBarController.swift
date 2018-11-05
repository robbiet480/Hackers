//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit
import RealmSwift

class MainTabBarController: UITabBarController, UITableViewDelegate {
    var moreTabTableViewDelegate: UITableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view: UITableView = self.moreNavigationController.viewControllers[0].view as? UITableView {
            self.moreTabTableViewDelegate = view.delegate
            view.delegate = self
        }

        self.delegate = self

        setupTheming()

        setTabBarOrder()

        tabBar.clipsToBounds = true

    }

    var settingsVC: UIViewController {
        let settingsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsView")
        settingsVC.title = "Settings"

        let icon = UIImage.fontAwesomeIcon(name: .cogs, style: .solid,
                                           textColor: AppThemeProvider.shared.currentTheme.barForegroundColor,
                                           size: CGSize(width: 30, height: 30))

        settingsVC.tabBarItem = UITabBarItem(title: settingsVC.title, image: icon, selectedImage: icon)

        return settingsVC
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setButtonStates(item.tag)
    }

    func setTabBarOrder() {
        let realm = Realm.live()

        if realm.objects(TabBarItem.self).count == 0 {
            print("Setting default tab order")
            setDefaultTabOrder()
        }

        let orderObjs = realm.objects(TabBarItem.self).sorted(byKeyPath: "index")

        var contentViews: [UIViewController] = []

        for tbi in orderObjs {
            if tbi.view == .Profile {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileView")
                guard let profileVC = vc as? ProfileViewController else { fatalError() }

                profileVC.title = UserDefaults.standard.loggedInUser?.Username

                profileVC.user = UserDefaults.standard.loggedInUser
                let barItem = tbi.view.barItem(tbi.index)
                barItem.title = UserDefaults.standard.loggedInUser?.Username
                profileVC.tabBarItem = barItem
                contentViews.append(AppNavigationController(rootViewController: profileVC))
            } else if tbi.view == .Leaderboard {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LeaderboardView")
                guard let leaderboardVC = vc as? LeaderboardTableViewController else { fatalError() }

                leaderboardVC.title = tbi.view.description

                leaderboardVC.tabBarItem = tbi.view.barItem(tbi.index)
                contentViews.append(AppNavigationController(rootViewController: leaderboardVC))
            } else if tbi.view == .Search {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchNav")
                guard let searchVCNav = vc as? AppNavigationController else { fatalError() }
                guard let searchVC = searchVCNav.topViewController as? SearchViewController else { fatalError() }

                searchVC.title = tbi.view.description

                searchVC.tabBarItem = tbi.view.barItem(tbi.index)
                contentViews.append(searchVCNav)
            } else {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
                guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
                guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

                newsVC.title = tbi.view.description

                newsVC.postType = tbi.view.scraperPage(tbi.associatedValue)
                newsVC.tabBarItem = tbi.view.barItem(tbi.index)
                contentViews.append(newsVCNav)
            }
        }

        self.setViewControllers(contentViews + [self.settingsVC], animated: true)

        self.customizableViewControllers = contentViews
    }

    func setButtonStates(_ itemTag: Int) {
        let normalTitleFont = UIFont.mySystemFont(ofSize: 12.0)
        let selectedTitleFont = UIFont.myBoldSystemFont(ofSize: 12.0)

        let tabs = self.tabBar.items

        var x = 0
        while x < (tabs?.count)! {

            if tabs?[x].tag == itemTag {
                tabs?[x].setTitleTextAttributes([NSAttributedString.Key.font: selectedTitleFont], for: UIControl.State.normal)
            } else {
                tabs?[x].setTitleTextAttributes([NSAttributedString.Key.font: normalTitleFont], for: UIControl.State.normal)
            }

            x += 1

        }

    }

    func setDefaultTabOrder() {
        let realm = Realm.live()

        guard realm.objects(TabBarItem.self).count == 0 else { return }

        var order: [TabBarItem] = [
            TabBarItem(0, HNScraper.Page.Home),
            TabBarItem(1, HNScraper.Page.AskHN),
            TabBarItem(2, .Search),
            TabBarItem(3, HNScraper.Page.Jobs),
            TabBarItem(4, HNScraper.Page.New),
            TabBarItem(5, HNScraper.Page.ShowHN),
            TabBarItem(6, HNScraper.Page.Active),
            TabBarItem(7, HNScraper.Page.Best),
            TabBarItem(8, HNScraper.Page.Noob),
            TabBarItem(9, HNScraper.Page.ForDate(date: nil)),
            TabBarItem(10, .Leaderboard),
        ]

        if let user = UserDefaults.standard.loggedInUser {

            order = [
                TabBarItem(0, HNScraper.Page.Home),
                TabBarItem(1, HNScraper.Page.AskHN),
                TabBarItem(2, .Profile),
                TabBarItem(3, .Search),
                TabBarItem(4, HNScraper.Page.Jobs),
                TabBarItem(5, HNScraper.Page.New),
                TabBarItem(6, HNScraper.Page.ShowHN),
                TabBarItem(7, HNScraper.Page.Active),
                TabBarItem(8, HNScraper.Page.Best),
                TabBarItem(9, HNScraper.Page.Noob),
                TabBarItem(10, HNScraper.Page.ForDate(date: nil)),
                TabBarItem(11, .Leaderboard),
                TabBarItem(12, HNScraper.Page.SubmissionsForUsername(username: user.Username)),
                TabBarItem(13, HNScraper.Page.FavoritesForUsername(username: user.Username)),
                TabBarItem(14, HNScraper.Page.Upvoted(username: user.Username))
            ]
        }

        try! realm.write {
            realm.add(order)
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, willBeginCustomizing viewControllers: [UIViewController]) {

        // Found at http://runmad.com/blog/2010/01/coloring-fun-with-morenavigationcontroller-and-it/

        let editView = self.view.subviews[1]
        editView.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

        if let navigationBar = editView.subviews[1] as? UINavigationBar {
            navigationBar.barTintColor = AppThemeProvider.shared.currentTheme.barBackgroundColor
            navigationBar.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
        }

    }

    // Tab Bar keyboard shortcuts found at
    // https://stablekernel.com/creating-a-delightful-user-experience-with-ios-keyboard-shortcuts/
    func getTabBarKeyCommands() -> [UIKeyCommand] {
        return self.tabBar.items!.enumerated().map { (index, item) -> UIKeyCommand in

            var discoverabilityTitle = item.title ?? item.title ?? "Tab \(index + 1)"

            if index == 7 {
                discoverabilityTitle = "More"
            }

            return UIKeyCommand(input: (index + 1).description, modifierFlags: .command,
                                action: #selector(selectTab), discoverabilityTitle: discoverabilityTitle)
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        return self.getTabBarKeyCommands()
    }

    @objc func selectTab(sender: UIKeyCommand) {
        if let newIndex = Int(sender.input!), newIndex >= 1 && newIndex <= (self.tabBar.items?.count ?? 0) {
            self.selectedIndex = newIndex - 1;
        }
    }

    // These tableView functions control the more tab
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        moreTabTableViewDelegate?.tableView!(tableView, willDisplay: cell, forRowAt: indexPath)
        cell.textLabel!.textColor = AppThemeProvider.shared.currentTheme.textColor
        cell.textLabel!.font = UIFont.mySystemFont(ofSize: 18.0)
        cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        moreTabTableViewDelegate?.tableView!(tableView, didSelectRowAt: indexPath)
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if viewController == self.moreNavigationController {

            let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self,
                                              action: #selector(MainTabBarController.handleMoreReset(_:)))

            self.moreNavigationController.topViewController?.navigationItem.leftBarButtonItem = resetButton


        }

        return true
    }

    // Saves new tab bar custom order
    func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
        if changed {
            let realm = Realm.live()
            let existingTabBarItems = realm.objects(TabBarItem.self)

            try! realm.write {
                realm.delete(existingTabBarItems)
            }

            var newVCOrder: [TabBarItem] = []

            for (index, viewController) in viewControllers.enumerated() {
                guard let navigationController = viewController as? UINavigationController,
                    let newsViewController = navigationController.topViewController as? NewsViewController,
                    let tbi = TabBarItem.View(newsViewController.postType)
                    else {
                        continue
                }

                newVCOrder.append(TabBarItem(index, tbi))
            }

            try! realm.write {
                realm.add(newVCOrder)
            }
        }
    }

    @objc func handleMoreReset(_ sender: Any) {
        let realm = Realm.live()

        let existingTabBarItems = realm.objects(TabBarItem.self)

        try! realm.write {
            realm.delete(existingTabBarItems)
        }

        self.setTabBarOrder()
    }
}

extension MainTabBarController: Themed {
    func applyTheme(_ theme: AppTheme) {
        tabBar.barTintColor = theme.barBackgroundColor
        tabBar.tintColor = theme.barForegroundColor

        if let application = UIApplication.shared.delegate as? AppDelegate,
            let tabBarController = application.window?.rootViewController as? UITabBarController {

            let selectedIndex = tabBarController.selectedIndex
            self.setButtonStates(selectedIndex)
        }

        self.moreNavigationController.navigationBar.barTintColor = AppThemeProvider.shared.currentTheme.barBackgroundColor
        self.moreNavigationController.navigationBar.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
        self.moreNavigationController.navigationBar.prefersLargeTitles = true
        self.moreNavigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.navigationBarTextColor,
            NSAttributedString.Key.font: UIFont.mySystemFont(ofSize: 17.0)]
        self.moreNavigationController.navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.navigationBarTextColor,
            NSAttributedString.Key.font: UIFont.myBoldSystemFont(ofSize: 31.0)]

        self.moreNavigationController.view.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

        if let view: UITableView = self.moreNavigationController.viewControllers[0].view as? UITableView {
            view.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
            view.separatorColor = AppThemeProvider.shared.currentTheme.separatorColor
            view.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
        }
    }
}
