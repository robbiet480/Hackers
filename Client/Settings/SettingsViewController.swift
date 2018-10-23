//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        self.tableView.bounces = false

        PickerInlineRow<String>.defaultCellUpdate = defaultCellUpdate

        SwitchRow.defaultCellUpdate = defaultCellUpdate

        IntRow.defaultCellUpdate = defaultCellUpdate

        form
            +++ PickerInlineRow<String>("theme") {
                $0.title = "Theme"
                $0.options = ["Light", "Dark", "Black", "Original"]
                $0.value = UserDefaults.standard.enabledTheme.description
            }.onChange {
                if let rowVal = $0.value {
                    UserDefaults.standard.setTheme(rowVal)
                    AppThemeProvider.shared.currentTheme = UserDefaults.standard.enabledTheme
                }
            }

            +++ PickerInlineRow<String>() {
                $0.title = "Open Links In"
                $0.options = ["In-app browser", "In-app browser (Reader mode)", "Safari", "Google Chrome"]
                $0.value = "In-app browser"
                $0.value = UserDefaults.standard.string(forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
            }.onChange {
                if let rowVal = $0.value {
                    UserDefaults.standard.setOpenLinksIn(rowVal)
                }
            }

            +++ Section(header: "Notifications", footer: "")
            <<< SwitchRow { row in
                row.tag = "enableNotifications"
                row.title = "Enable Notifications"
                row.value = Notifications.isLocalNotificationEnabled
            }.onChange { row in
                if let value = row.value {
                    Notifications.isLocalNotificationEnabled = value
                    if value == true {
                        Notifications.configure()
                    }
                }
            }

            <<< IntRow { row in
                row.tag = "pointsThreshold"
                row.title = "Minimum points for notification"
                row.value = UserDefaults.standard.minimumPointsForNotification
                row.hidden = "$enableNotifications == false"
            }.onChange { row in
                if let value = row.value {
                    UserDefaults.standard.minimumPointsForNotification = value
                }
            }
    }
    
    @IBAction func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc func multipleSelectorDone(_ item:UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
    }

    var defaultCellUpdate: ((BaseCell, BaseRow) -> Void)? {
        return { cell, row in
            let activeTheme = UserDefaults.standard.enabledTheme
            cell.textLabel?.textColor = .white
            cell.textLabel?.tintColor = .white
            cell.detailTextLabel?.textColor = activeTheme.lightTextColor
            cell.backgroundColor = activeTheme.barBackgroundColor
            cell.tintColor = activeTheme.lightTextColor
            row.baseCell.tintColor = activeTheme.lightTextColor

            if let textCell = cell as? TextFieldCell {
                textCell.textField.textColor = activeTheme.titleTextColor
            }

            if let pickerRow = row as? PickerInlineRow<String>, let inlineRow = pickerRow.inlineRow {
                inlineRow.cell.pickerTextAttributes = [.foregroundColor: activeTheme.titleTextColor]
            }
        }
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.barBackgroundColor
        tableView.backgroundColor = theme.barBackgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
