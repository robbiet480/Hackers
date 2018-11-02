//
//  MainSplitViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/02/2015.
//  Copyright (c) 2015 Glass Umbrella. All rights reserved.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTheming()
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredDisplayMode = .allVisible
    }
    // From https://gist.github.com/max-potapov/aba3bb026e9911d091f0c70af4cc13e6
//    private var master: UITabBarController {
//        return viewControllers.first as! UITabBarController
//    }
//
//    private var detail: UINavigationController {
//        return viewControllers.last as! UINavigationController
//    }
//
//    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
//        guard splitViewController.isCollapsed else { return false }
//        guard let selected = master.selectedViewController as? UINavigationController else { return false }
//        let controller: UIViewController
//        if let navigation = vc as? UINavigationController {
//            controller = navigation.topViewController!
//        } else {
//            controller = vc
//        }
//        controller.hidesBottomBarWhenPushed = true
//        selected.pushViewController(controller, animated: true)
//        return true
//    }
//
//    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
//        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
//        guard let topAsDetailController = secondaryAsNavController.topViewController, topAsDetailController is CommentsViewController else { return false }
//        guard let tabBar = primaryViewController as? UITabBarController else { return false }
//        for controller in tabBar.viewControllers! {
//            guard let navigation = controller as? UINavigationController else { continue }
//            guard let master = navigation.topViewController as? NewsViewController, master.collapseDetailViewController == false else { continue }
//            topAsDetailController.hidesBottomBarWhenPushed = true
//            navigation.pushViewController(topAsDetailController, animated: false)
//            return true
//        }
//        return false
//    }
//
//    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
//        guard let selected = master.selectedViewController as? UINavigationController else { return nil }
//        guard selected.topViewController is CommentsViewController else { return nil }
//        guard let details = selected.popViewController(animated: false) else { return nil }
//        return UINavigationController(rootViewController: details)
//    }

    // From https://stackoverflow.com/a/46012353/486182
    /* func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        print("Returning true")
        return true
    }

    // From https://stackoverflow.com/a/46012353/486182
    func splitViewController(_ splitViewController: UISplitViewController,
                             showDetail vc: UIViewController,
                             sender: Any?) -> Bool {

        if splitViewController.isCollapsed {
            guard let tabBarController = splitViewController.viewControllers.first as? UITabBarController else { fatalError() }
            guard let selectedNavigationViewController = tabBarController.selectedViewController as? UINavigationController else { fatalError() }

            // Push view controller
            var detailViewController = vc
            if let navController = vc as? UINavigationController, let topViewController = navController.topViewController {
                detailViewController = topViewController
            }
            selectedNavigationViewController.pushViewController(detailViewController, animated: true)
            return true
        }

        return false
    }*/

    // From https://stackoverflow.com/a/31370084/486182
    /*override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            if let tabBarController = self.viewControllers[0] as? UITabBarController {
                if let navigationController = tabBarController.selectedViewController as? UINavigationController {
                    navigationController.show(vc, sender: sender)
                    return
                }
            }
        }

        super.showDetailViewController(vc, sender: sender)
    }*/

    // Excellent UISplitViewController keyboard shortcuts tutorial/code from
    // https://chariotsolutions.com/blog/post/handling-keyboard-shortcuts-ios/

    override var keyCommands: [UIKeyCommand]? {
        let topCommands = keyCommandsFor(viewController: viewControllers.last)
        let bottomCommands = keyCommandsFor(viewController: viewControllers.first)

        var allCommands = [UIKeyCommand]()
        if let top = topCommands, let bottom = bottomCommands {
            allCommands = bottom
            allCommands.append(contentsOf: top)
        } else if let top = topCommands {
            allCommands = top
        } else if let bottom = bottomCommands {
            allCommands = bottom
        }

        if allCommands.count > 0 {
            var returnCommands = [UIKeyCommand]()
            for command in allCommands {
                returnCommands.append(UIKeyCommand(input: command.input ?? "", modifierFlags: command.modifierFlags,
                                                   action: #selector(handleKeyCommand(_:)),
                                                   discoverabilityTitle: command.discoverabilityTitle ?? ""))
            }
            return returnCommands
        } else {
            return nil
        }
    }

    private func keyCommandsFor(viewController baseController: UIViewController?) -> [UIKeyCommand]? {
        var keyCommands: [UIKeyCommand]?

        if let provider = keyCommandProvider(forViewController: baseController) {
            keyCommands = provider.shortcutKeys
        }

        return keyCommands
    }

    @objc func handleKeyCommand(_ command: UIKeyCommand) {
        let handled = handleKeyCommand(command, withBaseController: viewControllers.last)

        if !handled {
            handleKeyCommand(command, withBaseController: viewControllers.first)
        }
    }

    @discardableResult
    private func handleKeyCommand(_ command: UIKeyCommand, withBaseController viewController: UIViewController?) -> Bool {
        var handled = false

        if let provider = keyCommandProvider(forViewController: viewController) {
            handled = provider.handleShortcut(keyCommand: command)
        }

        return handled
    }

    private func keyCommandProvider(forViewController viewController: UIViewController?) -> KeyCommandProvider? {
        var provider: KeyCommandProvider?

        if let top = viewController {
            if let nav = top as? UINavigationController {
                var controller: UIViewController? = nav.topViewController
                while (controller != nil && controller!.isKind(of: UINavigationController.classForCoder())) {
                    controller = (controller as? UINavigationController)?.topViewController
                }
                if let controller = controller as? KeyCommandProvider {
                    provider = controller
                } else if let navProvider = nav as? KeyCommandProvider {
                    provider = navProvider
                } else if let topProvider = top as? KeyCommandProvider {
                    provider = topProvider
                }
            }
        }

        return provider
    }
}

extension MainSplitViewController: Themed {
    // Using the MainSplitViewController as a place to handle global theme changes
    func applyTheme(_ theme: AppTheme) {
        UITextView.appearance().tintColor = theme.appTintColor
        UITabBar.appearance().tintColor = theme.appTintColor

        /// It's not ideal to use UIApplication.shared but overriding preferredStatusBarStyle
        /// doesn't work with a UITabBarController and UISplitViewController
        UIApplication.shared.statusBarStyle = theme.statusBarStyle
    }
}

protocol KeyCommandProvider {
    var shortcutKeys: [UIKeyCommand] { get }
    func handleShortcut(keyCommand: UIKeyCommand) -> Bool
}
