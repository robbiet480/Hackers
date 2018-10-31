//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka
import OnePasswordExtension
import ContextMenu

class SettingsViewController: FormViewController {
    let autoBrightnessFooterText = "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes."

    let onepasswordButton: UIButton = UIButton()
    let pushExplainerButton: UIButton = UIButton(type: .detailDisclosure)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        let onePasswordBundle = Bundle(path:
            Bundle(for: OnePasswordExtension.self).path(forResource: "OnePasswordExtensionResources", ofType: "bundle")!)
        let onePasswordImage = UIImage(named: "onepassword-button", in: onePasswordBundle, compatibleWith: nil)

        self.pushExplainerButton.addTarget(self, action: #selector(openPushExplainer(_:)), for: .touchUpInside)

        self.onepasswordButton.setImage(onePasswordImage, for: .normal)
        self.onepasswordButton.addTarget(self, action: #selector(onepasswordButtonPressed(_:)), for: .touchUpInside)

        setRowDefaults()

        let displaySectionFooter = UserDefaults.standard.automaticThemeSwitch ? self.autoBrightnessFooterText : ""

        let lightThemeRowLabel = UserDefaults.standard.automaticThemeSwitch ? "Light Theme" : "Theme"

        form
            +++ Section(header: "General", footer: "")
            <<< PickerInlineRow<OpenInBrowser.OpenableBrowser>() {
                    $0.title = "Open Links In"
                    $0.options = OpenInBrowser.shared.installedBrowsers
                    $0.value = OpenInBrowser.shared.browser
                    $0.displayValueFor = { $0?.description }
                }.onChange {
                    if let rowVal = $0.value {
                        OpenInBrowser.shared.browser = rowVal
                    }
                }.onExpandInlineRow(inlineStringPickerOnExpandInlineRow)

            <<< SwitchRow("animateUpdates") {
                    $0.title = "Animate realtime updates"
                    $0.value = UserDefaults.standard.animateUpdates
                }.onChange { row in
                    UserDefaults.standard.animateUpdates = row.value!
            }

            +++ Section(header: "Login",
                        footer: "Logging in allows you to upvote and downvote posts and comments as well as favorite posts. \r\n\r\nYour username and password is securely stored in Keychain and only ever sent to Hacker News/Y Combinator, never to the authors of Hackers.") {
                $0.tag = "login"
            }

            <<< LabelRow("loggedInUser") {
                $0.title = "Logged in as"
                $0.value = UserDefaults.standard.loggedInUser?.Username
                $0.hidden = Condition(booleanLiteral: UserDefaults.standard.loggedInUser == nil)
            }

            <<< AccountRow("username") {
                    $0.title = "Username"
                    $0.placeholder = ["pg", "dang", "tptacek", "jacquesm", "patio11"].randomElement()
                    $0.hidden = "$loggedInUser != nil"
                }.onChange { row in
                    var targetAlpha: CGFloat?
                    if row.value == "" {
                        targetAlpha = 1.0
                    } else if row.value != nil {
                        targetAlpha = 0.0
                    }
                    if let alpha = targetAlpha {
                        UIView.animate(withDuration: 0.25, animations: {
                            self.onepasswordButton.alpha = alpha
                        })
                    }
                }

            <<< PasswordRow("password") {
                    $0.title = "Password"
                    $0.placeholder = "hunter2"
                    $0.hidden = "$loggedInUser != nil"
                }

            <<< ButtonRow() {
                    $0.title = "Login"
                    $0.hidden = "$loggedInUser != nil"
            }.onCellSelection(handleLogin)

            <<< ButtonRow("logout") {
                $0.title = "Log out"
                $0.hidden = "$loggedInUser == nil"
            }.onCellSelection { _, row in
                UserDefaults.standard.loggedInUser = nil
                HNLogin.shared.Logout()

                if let usernameRow = self.form.rowBy(tag: "loggedInUser") as? LabelRow {
                    usernameRow.value = nil
                    usernameRow.hidden = true
                    usernameRow.evaluateHidden()
                }
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
                    $0.value = Float(UserDefaults.standard.brightnessLevelForThemeSwitch)
                    $0.hidden = "$switchThemeAutomatically == false"
                }.onChange { row in
                    UserDefaults.standard.brightnessLevelForThemeSwitch = CGFloat(row.value!)

                    NotificationCenter.default.post(name: UIScreen.brightnessDidChangeNotification, object: self,
                                                    userInfo: nil)
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

    var handleLogin: ((ButtonCell, ButtonRow) -> Void) {
        return { _, row in
            if let usernameRow = self.form.rowBy(tag: "username") as? AccountRow, let username = usernameRow.value,
                let passwordRow = self.form.rowBy(tag: "password") as? PasswordRow, let password = passwordRow.value {

                let spinner = UIViewController.displaySpinner(onView: self.navigationController!.view)

                HNLogin.shared.Login(username, password).done { user in
                    var loggedInUsername: String?

                    UIViewController.removeSpinner(spinner: spinner)

                    var alertVC = UIAlertController(title: "Unknown error",
                                                    message: "Received neither a valid response or error during login attempt",
                                                    preferredStyle: .alert)

                    if let user = user {
                        let username = user.Username
                        loggedInUsername = username
                        print("Login succeeded, got user", user.description)
                        alertVC = UIAlertController(title: "Success", message: "You are now logged in as \(username)", preferredStyle: .alert)
                        UserDefaults.standard.loggedInUser = user
                    }

                    alertVC.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))

                    if let username = loggedInUsername,
                        let usernameRow = self.form.rowBy(tag: "loggedInUser") as? LabelRow {
                        usernameRow.value = username
                        usernameRow.hidden = false
                        usernameRow.evaluateHidden()
                    }

                    self.present(alertVC, animated: true, completion: nil)
                }.catch { error in
                    UIViewController.removeSpinner(spinner: spinner)

                    let alertVC = UIAlertController(title: "Error during login", message: error.localizedDescription,
                                                    preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                }

            }
        }
    }

    var inlineStringPickerOnExpandInlineRow: ((PickerInlineCell<OpenInBrowser.OpenableBrowser>, PickerInlineRow<OpenInBrowser.OpenableBrowser>, PickerRow<OpenInBrowser.OpenableBrowser>) -> Void) {
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

                if OnePasswordExtension.shared().isAppExtensionAvailable() {
                    self.addButtonToCell(accountCell, self.onepasswordButton)
                }
            }

            if let passwordCell = cell as? PasswordCell {
                passwordCell.textField.textContentType = .password
            }

            if row.tag == "enableNotifications" {
                self.addButtonToCell(cell, self.pushExplainerButton)
            } else if row.tag == "logout" {
                cell.textLabel?.textColor = .red
            }
        }
    }

    @objc func openPushExplainer(_ sender: AnyObject) {
        self.showContextualMenu(PushNotificationsDisclaimerViewController())
    }

    @objc func onepasswordButtonPressed(_ sender: AnyObject) {
        let hnURL = "https://news.ycombinator.com"
        OnePasswordExtension.shared().findLogin(forURLString: hnURL, for: self, sender: sender) { (loginDictionary, error) in
            if loginDictionary == nil {
                if error!._code != Int(AppExtensionErrorCodeCancelledByUser), let error = error {
                    print("Error invoking 1Password App Extension for find login: \(error)")
                }
                return
            }

            self.form.setValues([
                "username": loginDictionary?[AppExtensionUsernameKey] as? String,
                "password": loginDictionary?[AppExtensionPasswordKey] as? String
            ])
            self.tableView?.reloadData()
        }
    }

    func addButtonToCell(_ cell: BaseCell, _ button: UIButton) {
        guard cell.contentView.subviews.contains(button) == false else { return }

        cell.contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            NSLayoutConstraint(item: button, attribute: .height,
                               relatedBy: .greaterThanOrEqual, toItem: cell.contentView,
                               attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .width,
                               relatedBy: .greaterThanOrEqual, toItem: cell.contentView,
                               attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .left,
                               relatedBy: .equal, toItem: cell.textLabel,
                               attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: button, attribute: .centerY,
                               relatedBy: .equal, toItem: cell.textLabel,
                               attribute: .centerY, multiplier: 1, constant: 0),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setRowDefaults() {
        AccountRow.defaultCellSetup = defaultCellUpdate
        AccountRow.defaultCellUpdate = defaultCellUpdate

        ButtonRow.defaultCellSetup = defaultCellUpdate
        ButtonRow.defaultCellUpdate = defaultCellUpdate

        IntRow.defaultCellSetup = defaultCellUpdate
        IntRow.defaultCellUpdate = defaultCellUpdate

        LabelRow.defaultCellSetup = defaultCellUpdate
        LabelRow.defaultCellUpdate = defaultCellUpdate

        PasswordRow.defaultCellSetup = defaultCellUpdate
        PasswordRow.defaultCellUpdate = defaultCellUpdate

        PickerInlineRow<AppTheme>.defaultCellSetup = defaultCellUpdate
        PickerInlineRow<AppTheme>.defaultCellUpdate = defaultCellUpdate

        PickerInlineRow<OpenInBrowser.OpenableBrowser>.defaultCellSetup = defaultCellUpdate
        PickerInlineRow<OpenInBrowser.OpenableBrowser>.defaultCellUpdate = defaultCellUpdate

        PickerInlineRow<String>.defaultCellSetup = defaultCellUpdate
        PickerInlineRow<String>.defaultCellUpdate = defaultCellUpdate

        SliderRow.defaultCellSetup = defaultCellUpdate
        SliderRow.defaultCellUpdate = defaultCellUpdate

        SwitchRow.defaultCellSetup = defaultCellUpdate
        SwitchRow.defaultCellUpdate = defaultCellUpdate
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
