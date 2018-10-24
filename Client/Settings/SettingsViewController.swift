//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka
import ContextMenu

class SettingsViewController: FormViewController {
    let autoBrightnessFooterText = "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes."

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        PickerInlineRow<String>.defaultCellUpdate = defaultCellUpdate
        PickerInlineRow<AppTheme>.defaultCellUpdate = defaultCellUpdate

        SwitchRow.defaultCellUpdate = defaultCellUpdate

        IntRow.defaultCellUpdate = defaultCellUpdate

        SliderRow.defaultCellUpdate = defaultCellUpdate

        let displaySectionFooter = UserDefaults.standard.automaticThemeSwitch ? self.autoBrightnessFooterText : ""

        let lightThemeRowLabel = UserDefaults.standard.automaticThemeSwitch ? "Light Theme" : "Theme"

        form
            +++ Section(header: "General", footer: "")
            <<< PickerInlineRow<String>() {
                    $0.title = "Open Links In"
                    $0.options = ["In-app browser", "In-app browser (Reader mode)", "Safari", "Google Chrome"]
                    $0.value = "In-app browser"
                    $0.value = UserDefaults.standard.string(forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
                }.onChange {
                    if let rowVal = $0.value {
                        UserDefaults.standard.setOpenLinksIn(rowVal)
                    }
                }.onExpandInlineRow(inlineStringPickerOnExpandInlineRow)

            <<< SwitchRow("animateUpdates") {
                    $0.title = "Highlight item title on comment and point updates"
                    $0.value = UserDefaults.standard.animateUpdates
                }.onChange { row in
                    UserDefaults.standard.animateUpdates = row.value!
            }

            +++ Section(header: "Theme", footer: displaySectionFooter)
            <<< PickerInlineRow<AppTheme>("lightTheme") {
                    $0.title = lightThemeRowLabel
                    $0.options = AppThemeProvider.shared.availableThemes
                    $0.value = UserDefaults.standard.lightTheme
                    $0.displayValueFor = { $0?.description }
                }.onChange {
                    if let rowVal = $0.value {
                        UserDefaults.standard.lightTheme = rowVal
                        AppThemeProvider.shared.currentTheme = UserDefaults.standard.brightnessCorrectTheme
                    }
                }.onExpandInlineRow(inlineAppThemePickerOnExpandInlineRow)

            <<< PickerInlineRow<AppTheme>("darkTheme") {
                    $0.title = "Dark Theme"
                    $0.options = AppThemeProvider.shared.availableThemes
                    $0.value = UserDefaults.standard.darkTheme
                    $0.displayValueFor = { $0?.description }
                    $0.hidden = Condition(booleanLiteral: !UserDefaults.standard.automaticThemeSwitch)
                }.onChange {
                    if let rowVal = $0.value {
                        UserDefaults.standard.darkTheme = rowVal
                        AppThemeProvider.shared.currentTheme = UserDefaults.standard.brightnessCorrectTheme
                    }
                }.onExpandInlineRow(inlineAppThemePickerOnExpandInlineRow)

            <<< SwitchRow("switchThemeAutomatically") {
                    $0.title = "Switch theme automatically"
                    $0.value = UserDefaults.standard.automaticThemeSwitch
                }.onChange { row in
                    UserDefaults.standard.automaticThemeSwitch = row.value!

                    if let lightThemeRow = self.form.rowBy(tag: "lightTheme") {
                        lightThemeRow.title = row.value! ? "Light Theme" : "Theme"
                        lightThemeRow.updateCell()
                    }

                    if let darkThemeRow = self.form.rowBy(tag: "darkTheme") {
                        darkThemeRow.hidden = Condition(booleanLiteral: !row.value!)
                        darkThemeRow.evaluateHidden()
                    }

                    if row.value! {
                        row.section!.footer = HeaderFooterView(title: self.autoBrightnessFooterText)
                    } else {
                        row.section!.footer = nil
                    }

                    row.section!.reload()
                }

            <<< SliderRow("brightnessSlider") {
                    $0.title = "Brightness"
                    $0.shouldHideValue = true
                    $0.steps = 100
                    $0.cell.slider.minimumValue = 0.0
                    $0.cell.slider.maximumValue = 1.0
                    $0.cell.slider.isContinuous = false
                    $0.value = UserDefaults.standard.brightnessLevelForThemeSwitch
                    $0.hidden = "$switchThemeAutomatically == false"
                }.onChange { row in
                    UserDefaults.standard.brightnessLevelForThemeSwitch = row.value!

                    NotificationCenter.default.post(name: UIScreen.brightnessDidChangeNotification,
                                                    object: self, userInfo: nil)
                }

            +++ Section(header: "Notifications", footer: "")
            <<< SwitchRow { row in
                row.tag = "enableNotifications"
                row.title = "Enable Notifications"
                row.value = Notifications.isLocalNotificationEnabled
            }.onChange { row in
                Notifications.isLocalNotificationEnabled = row.value!
                if row.value! == true {
                    Notifications.configure()
                }
            }.onCellSelection { _, _ in
                self.showContextualMenu(PushNotificationsDisclaimerViewController())
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

    var inlineStringPickerOnExpandInlineRow: ((PickerInlineCell<String>, PickerInlineRow<String>, PickerRow<String>) -> Void) {
        return { _, _, row in
            row.cellUpdate { cell, _ in
                cell.pickerTextAttributes = [
                    NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.barForegroundColor
                ]
                cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
            }
        }
    }

    var inlineAppThemePickerOnExpandInlineRow: ((PickerInlineCell<AppTheme>, PickerInlineRow<AppTheme>, PickerRow<AppTheme>) -> Void) {
        return { _, _, row in
            row.cellUpdate { cell, _ in
                cell.pickerTextAttributes = [
                    NSAttributedString.Key.foregroundColor: AppThemeProvider.shared.currentTheme.barForegroundColor
                ]
                cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
            }
        }
    }

    var defaultCellUpdate: ((BaseCell, BaseRow) -> Void)? {
        return { cell, row in
            let activeTheme = AppThemeProvider.shared.currentTheme
            cell.textLabel?.textColor = activeTheme.textColor
            cell.textLabel?.tintColor = activeTheme.textColor
            cell.detailTextLabel?.textColor = activeTheme.barForegroundColor
            cell.detailTextLabel?.tintColor = activeTheme.barForegroundColor
            cell.backgroundColor = activeTheme.barBackgroundColor
            cell.tintColor = activeTheme.lightTextColor
            row.baseCell.tintColor = activeTheme.lightTextColor

            if let textCell = cell as? TextFieldCell {
                textCell.textField.textColor = activeTheme.titleTextColor
            }

            if let switchCell = cell as? SwitchCell {
                switchCell.switchControl.onTintColor = activeTheme.barForegroundColor
                switchCell.switchControl.tintColor = activeTheme.barForegroundColor
            }

            if let sliderCell = cell as? SliderCell {
                sliderCell.slider.tintColor = AppThemeProvider.shared.currentTheme.barForegroundColor
            }

            if row.tag == "enableNotifications" {
                let existingButton = cell.textLabel?.subviews.first(where: { (view) -> Bool in
                    return view.tag == 999
                })
                if let button = existingButton {
                    button.frame = CGRect(x: cell.textLabel!.intrinsicContentSize.width + 5, y: button.frame.minY,
                                              width: button.frame.width, height: button.frame.height)
                } else {
                    let button = UIButton(type: .detailDisclosure)
                    button.tag = 999
                    button.frame = CGRect(x: cell.textLabel!.intrinsicContentSize.width + 5, y: button.frame.minY,
                                          width: button.frame.width, height: button.frame.height)
                    cell.textLabel!.addSubview(button)
                }
            }
        }
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.barBackgroundColor
        tableView.backgroundColor = theme.barBackgroundColor
        tableView.separatorColor = theme.separatorColor

        self.tableView.reloadData()
    }
}
