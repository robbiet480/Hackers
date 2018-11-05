//
//  AppThemeProvider.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import UIKit
import Eureka

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

    var eurekaCellUpdate: ((BaseCell, BaseRow) -> Void) {
        return { cell, row in
            let activeTheme = AppThemeProvider.shared.currentTheme
            cell.textLabel?.textColor = activeTheme.textColor
            cell.textLabel?.tintColor = activeTheme.textColor
            cell.detailTextLabel?.textColor = activeTheme.barForegroundColor
            cell.detailTextLabel?.tintColor = activeTheme.barForegroundColor
            cell.backgroundColor = activeTheme.backgroundColor
            cell.tintColor = activeTheme.barForegroundColor

            if let textFieldCell = cell as? TextFieldCell {
                textFieldCell.textField.tintColor = activeTheme.barForegroundColor
                textFieldCell.textField.textColor = activeTheme.barForegroundColor
            }

            if let buttonCell = cell as? ButtonCellOf<String> {
                buttonCell.textLabel?.textColor = activeTheme.barForegroundColor
                buttonCell.textLabel?.tintColor = activeTheme.barForegroundColor
            }

            if let switchCell = cell as? SwitchCell {
                switchCell.switchControl.onTintColor = activeTheme.barForegroundColor
                switchCell.switchControl.tintColor = activeTheme.barForegroundColor
            }

            if let sliderCell = cell as? SliderCell {
                sliderCell.slider.tintColor = activeTheme.barForegroundColor
            }

            if let accountCell = cell as? AccountCell {
                accountCell.textField.textContentType = .username
            }

            if let passwordCell = cell as? PasswordCell {
                passwordCell.textField.textContentType = .password
            }

            if let textAreaCell = cell as? TextAreaCell {
                textAreaCell.textView.tintColor = activeTheme.barForegroundColor
                textAreaCell.textView.textColor = activeTheme.barForegroundColor
            }
        }
    }
}

extension Themed where Self: AnyObject {
    var themeProvider: AppThemeProvider {
        return AppThemeProvider.shared
    }
}
