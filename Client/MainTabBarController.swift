//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit
import RealmSwift

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

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
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
            guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
            guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

            newsVC.title = tbi.view.description

            newsVC.postType = tbi.view.scraperPage(tbi.associatedValue)
            newsVC.tabBarItem = tbi.view.barItem(tbi.index)
            contentViews.append(newsVCNav)
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
            TabBarItem(2, HNScraper.Page.Jobs),
            TabBarItem(3, HNScraper.Page.New),
            TabBarItem(4, HNScraper.Page.ShowHN),
            TabBarItem(5, HNScraper.Page.Active),
            TabBarItem(6, HNScraper.Page.Best),
            TabBarItem(7, HNScraper.Page.Noob),
            TabBarItem(8, HNScraper.Page.ForDate(date: nil)),
        ]

        if let user = UserDefaults.standard.loggedInUser {
            order.append(TabBarItem(9, HNScraper.Page.SubmissionsForUsername(username: user.Username)))
            order.append(TabBarItem(10, HNScraper.Page.FavoritesForUsername(username: user.Username)))
            order.append(TabBarItem(11, HNScraper.Page.Upvoted(username: user.Username)))
        }

        try! realm.write {
            realm.add(order)
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, willBeginCustomizing viewControllers: [UIViewController]) {

        // Found at http://runmad.com/blog/2010/01/coloring-fun-with-morenavigationcontroller-and-it/

        let editView = tabBarController.view.subviews[1]
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
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if viewController == tabBarController.moreNavigationController {

            let moreNavController = viewController as! UINavigationController

            let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self,
                                              action: #selector(MainTabBarController.handleMoreReset(_:)))

            tabBarController.moreNavigationController.topViewController?.navigationItem.leftBarButtonItem = resetButton

            moreNavController.navigationBar.barTintColor = AppThemeProvider.shared.currentTheme.barBackgroundColor
            moreNavController.navigationBar.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
            moreNavController.navigationBar.prefersLargeTitles = true
            moreNavController.navigationBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.navigationBarTextColor,
                NSAttributedString.Key.font: UIFont.mySystemFont(ofSize: 17.0)]
            moreNavController.navigationBar.largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.navigationBarTextColor,
                NSAttributedString.Key.font: UIFont.myBoldSystemFont(ofSize: 31.0)]

            moreNavController.view.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

            if tabBarController.moreNavigationController.topViewController?.view is UITableView {
                let view: UITableView = tabBarController.moreNavigationController.topViewController?.view as! UITableView

                view.bounces = false

                view.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
                view.separatorColor = AppThemeProvider.shared.currentTheme.separatorColor
                view.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

                for cell in view.visibleCells {
                    cell.textLabel!.textColor = AppThemeProvider.shared.currentTheme.textColor
                    cell.textLabel!.font = UIFont.mySystemFont(ofSize: 18.0)
                    cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
                }
            }
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
            let splitViewController = application.window?.rootViewController as? UISplitViewController,
            let tabBarController = splitViewController.viewControllers[0] as? UITabBarController {

            let selectedIndex = tabBarController.selectedIndex
            self.setButtonStates(selectedIndex)
        }
    }
}
