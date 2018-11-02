//
//  AppNavigationController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class AppNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        navigationBar.setValue(true, forKey: "hidesShadow")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("AppNav did appear!")
    }
}

extension AppNavigationController: Themed {
    func applyTheme(_ theme: AppTheme) {        
        navigationBar.barTintColor = theme.barBackgroundColor
        navigationBar.tintColor = theme.barForegroundColor
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.navigationBarTextColor,
            NSAttributedString.Key.font: UIFont.mySystemFont(ofSize: 17.0)]
        navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.navigationBarTextColor,
            NSAttributedString.Key.font: UIFont.myBoldSystemFont(ofSize: 31.0)]
    }
}
