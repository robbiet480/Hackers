//
//  ProfileViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/4/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka

class ProfileViewController: FormViewController {

    var user: HNUser?

    var previousNavTextColor: UIColor?

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()

        LabelRow.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        LabelRow.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        TextAreaRow.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        TextAreaRow.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        ButtonRow.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        ButtonRow.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        guard let user = self.user else { return }

        _ = HNScraper.shared.GetUser(user.Username, dataSource: HTMLDataSource()).done {
            self.user = $0

            guard let user = $0 else { return }

            self.title = user.Username

            self.form
                +++ Section(header: "Stats", footer: "")

            if let createdAt = user.CreatedAt {
                self.form.last!
                    <<< LabelRow("created") {
                        $0.title = "Created"

                        $0.value = self.dateFormatter.string(from: createdAt)
                    }.onCellSelection { _, _ in
                        self.show(self.getNewsVC(.ForDate(date: createdAt)), sender: self)
                    }
            }

            if let updatedAt = user.UpdatedAt {
                self.form.last!
                    <<< LabelRow("updatedAt") {
                            $0.title = "Updated At"

                            $0.value = self.dateFormatter.string(from: updatedAt)
                        }
            }

            self.form.last!
                <<< LabelRow("karma") {
                    $0.title = "Karma"

                    $0.value = user.Karma.delimiter
                }

            if let commentCount = user.CommentCount {
                self.form.last!
                    <<< LabelRow("commentCount") {
                        $0.title = "Comments Count"

                        $0.value = String(commentCount)
                    }
            }

            if let submissionCount = user.SubmissionCount {
                self.form.last!
                    <<< LabelRow("submissionCount") {
                        $0.title = "Submissions Count"

                        $0.value = String(submissionCount)
                }
            }

            if user.IsYC {
                self.form
                +++ Section(header: "Y Combinator",
                            footer: "This information is only visible to those that have completed YC")

                if let name = user.Name, !name.isEmpty {
                    self.form.last!
                        <<< LabelRow("name") {
                            $0.title = "Name"

                            $0.value = name
                    }
                }

                if let bio = user.Bio, !bio.isEmpty {
                    self.form.last!
                        <<< LabelRow("bio") {
                            $0.title = "Bio"
                            $0.value = bio
                    }
                }
            }

            if let about = user.About, !about.isEmpty {

                let attrText = NSAttributedString(string: about.htmlDecoded,
                                                  attributes: [
                                                    .font: UIFont.mySystemFont(ofSize: 14.0),
                                                    .backgroundColor: AppThemeProvider.shared.currentTheme.backgroundColor,
                                                    .foregroundColor: AppThemeProvider.shared.currentTheme.textColor,
                                                  ])

                self.form
                    +++ Section(header: "About", footer: "")
                    <<< TextAreaRow("about") {
                        $0.title = "About"
                        $0.placeholder = "N/A"
                        $0.textAreaHeight = .dynamic(initialTextViewHeight: 30)
                        $0.disabled = true
                        $0.value = attrText.string
                        $0.cell.textView.isEditable = false
                        $0.cell.textView.dataDetectorTypes = [.link]
                        $0.cell.textView.delegate = self
                        $0.cell.textView.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
                    }.cellUpdate { cell, row in
                        cell.textView.text = nil
                        cell.textView.attributedText = attrText
                    }
            }

            self.form
                +++ Section()

                /*<<< ButtonRow("comments") {
                    $0.title = "Comments"
                    $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                        return self.getNewsVC(.CommentsForUsername(username: user.Username))
                    }, onDismiss: { vc in
                        _ = vc.navigationController?.popViewController(animated: true)
                    })
                }*/
                <<< ButtonRow("submissions") {
                    $0.title = "Submissions"
                    $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                        return self.getNewsVC(.SubmissionsForUsername(username: user.Username))
                    }, onDismiss: { vc in
                        _ = vc.navigationController?.popViewController(animated: true)
                    })
                }
                <<< ButtonRow("favorites") {
                    $0.title = "Favorites"
                    $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                        return self.getNewsVC(.FavoritesForUsername(username: user.Username))
                    }, onDismiss: { vc in
                        _ = vc.navigationController?.popViewController(animated: true)
                    })
                }

            if user.Username == UserDefaults.standard.loggedInUser!.Username {
                self.form.last!
                    <<< ButtonRow("hidden") {
                        $0.title = "Hidden"
                        $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                            return self.getNewsVC(.Hidden(username: user.Username))
                        }, onDismiss: { vc in
                            _ = vc.navigationController?.popViewController(animated: true)
                        })
                    }
                    /*<<< ButtonRow("upvotedComments") {
                        $0.title = "Upvoted Comments"
                        $0.disabled = true
                        $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                            return self.getNewsVC(.Upvoted(username: user.Username))
                        }, onDismiss: { vc in
                            _ = vc.navigationController?.popViewController(animated: true)
                        })
                    }*/
                    <<< ButtonRow("upvotedSubmissions") {
                        $0.title = "Upvoted Submissions"
                        $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                            return self.getNewsVC(.Upvoted(username: user.Username))
                        }, onDismiss: { vc in
                            _ = vc.navigationController?.popViewController(animated: true)
                        })
                    }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let user = self.user {
            if self.previousNavTextColor == nil,
                let attrs = self.navigationController?.navigationBar.titleTextAttributes,
                let color = attrs[.foregroundColor] as? UIColor {
                self.previousNavTextColor = color
            }

            self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: user.Color]
            self.navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: user.Color]
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let color = self.previousNavTextColor {
            self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: color]
            self.navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: color]
        }
    }

    func getNewsVC(_ postType: HNScraper.Page) -> UIViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
        guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
        guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

        newsVC.title = postType.description

        if case .ForDate = postType {
            newsVC.title = self.user!.Username + "'s birthday"
        }

        newsVC.pageType = postType

        newsVC.hideBarItems = true

        return newsVC
    }
}

extension ProfileViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        if let vc = OpenInBrowser.shared.openURL(URL) {
            self.present(vc, animated: true, completion: nil)
        }

        return false

    }
}

extension ProfileViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor

        self.tableView.reloadData()
    }
}
