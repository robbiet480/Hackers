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

        let realm = Realm.live()

        if realm.objects(TabBarItem.self).count == 0 {
            setDefaultTabOrder()
        }

        let orderObjs = realm.objects(TabBarItem.self).sorted(byKeyPath: "index")

        guard let viewControllers = self.viewControllers else { return }

        for (index, viewController) in viewControllers.enumerated() {
            guard let splitViewController = viewController as? UISplitViewController,
                let navigationController = splitViewController.viewControllers.first as? UINavigationController,
                let newsViewController = navigationController.viewControllers.first as? NewsViewController
                else {
                    return
            }

            let config = orderObjs[index]

            newsViewController.postType = config.view.scraperPage

            splitViewController.tabBarItem = config.view.barItem(index)
        }

        self.customizableViewControllers = viewControllers

        tabBar.clipsToBounds = true
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setButtonStates(item.tag)
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

        let defaultOrder: [TabBarItem.View] = [.Home, .AskHN, .Jobs, .New, .ShowHN, .Active, .Best, .Noob]

        let orderObjs: [TabBarItem] = defaultOrder.enumerated().map { (arg) -> TabBarItem in
            let (i, e) = arg
            return TabBarItem(i, e)
        }

        try! realm.write {
            realm.add(orderObjs)
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
        let allCommands = self.getTabBarKeyCommands()

        guard let splitVC = self.selectedViewController as? MainSplitViewController,
            let splitVCkeyCommands = splitVC.keyCommands else { return allCommands }

        return allCommands + splitVCkeyCommands
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
                guard let splitViewController = viewController as? UISplitViewController,
                    let navigationController = splitViewController.viewControllers.first as? UINavigationController,
                    let newsViewController = navigationController.viewControllers.first as? NewsViewController,
                    let tbi = TabBarItem.View(newsViewController.postType)
                    else {
                        return
                }

                newVCOrder.append(TabBarItem(index, tbi))
            }

            try! realm.write {
                realm.add(newVCOrder)
            }
        }
    }
}

extension MainTabBarController: Themed {
    func applyTheme(_ theme: AppTheme) {
        tabBar.barTintColor = theme.barBackgroundColor
        tabBar.tintColor = theme.barForegroundColor

        let application = UIApplication.shared.delegate as! AppDelegate
        let tabbarController = application.window?.rootViewController as! UITabBarController
        let selectedIndex = tabbarController.selectedIndex
        self.setButtonStates(selectedIndex)
    }
}
