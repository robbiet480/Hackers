//
//  AppThemeProvider.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import UIKit

final class AppThemeProvider: ThemeProvider {
    static let shared: AppThemeProvider = .init()
    
    private var theme: SubscribableValue<AppTheme>
    public var availableThemes: [AppTheme] = [.light, .dark, .original, .black]
    
    var currentTheme: AppTheme {
        get {
            return theme.value
        }
        set {
            if currentTheme == newValue { return }
            setNewTheme(newValue)
        }
    }
    
    init() {
        theme = SubscribableValue<AppTheme>(value: .light)
    }
    
    private func setNewTheme(_ newTheme: AppTheme) {
        print("New theme is being set!")
        let window = UIApplication.shared.delegate!.window!!
        UIView.transition(
            with: window,
            duration: 0.3,
            options: [UIView.AnimationOptions.transitionCrossDissolve],
            animations: {
                self.theme.value = newTheme
                UIFont.overrideInitialize()
        }, completion: nil)
    }
    
    func subscribeToChanges(_ object: AnyObject, handler: @escaping (AppTheme) -> Void) {
        theme.subscribe(object, using: handler)
    }
    
    func nextTheme() {
        guard let nextTheme = availableThemes.rotate() else {
            return
        }
        currentTheme = nextTheme
    }
}

extension Themed where Self: AnyObject {
    var themeProvider: AppThemeProvider {
        return AppThemeProvider.shared
    }
}
