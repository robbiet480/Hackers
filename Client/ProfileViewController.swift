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

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = self.user else { return }

        HNScraper.shared.GetUser(user.Username, dataSource: HTMLDataSource()).done {
            self.user = $0

            guard let user = $0 else { return }

            self.title = user.Username

            self.form
                +++ Section(header: "Stats", footer: "")

            if let createdAt = user.CreatedAt {
                self.form.last!
                    <<< LabelRow("age") {
                        $0.title = "Age"

                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE, MMM d, yyyy"

                        $0.value = formatter.string(from: createdAt)
                    }.onCellSelection { _, _ in
                        let vc = self.getNewsVC(.ForDate(date: createdAt))
                        self.show(vc, sender: self)
                    }
            }

            if let updatedAt = user.UpdatedAt {
                self.form.last!
                    <<< LabelRow("updatedAt") {
                            $0.title = "Updated At"

                            let formatter = DateFormatter()
                            formatter.dateFormat = "EEEE, MMM d, yyyy"

                            $0.value = formatter.string(from: updatedAt)
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
                self.form
                    +++ Section(header: "About", footer: "")
                    <<< TextAreaRow("about") {
                        $0.title = "About"
                        $0.textAreaHeight = .dynamic(initialTextViewHeight: 30)
                        $0.disabled = true
                        $0.value = about
                        $0.cell.textView.isEditable = false
                        $0.cell.textView.dataDetectorTypes = [.link]
                        $0.cell.textView.delegate = self
                }
            }

            self.form
                +++ Section()

                <<< ButtonRow("comments") {
                    $0.title = "Comments"
                    $0.disabled = true
                    $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                        return self.getNewsVC(.CommentsForUsername(username: user.Username))
                        }, onDismiss: { vc in
                            _ = vc.navigationController?.popViewController(animated: true)
                    })
                }
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
                    <<< ButtonRow("upvotedComments") {
                        $0.title = "Upvoted Comments"
                        $0.disabled = true
                        $0.presentationMode = .show(controllerProvider: ControllerProvider.callback {
                            return self.getNewsVC(.Upvoted(username: user.Username))
                            }, onDismiss: { vc in
                                _ = vc.navigationController?.popViewController(animated: true)
                        })
                    }
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

        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: self.user?.Color]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.navigationBar.titleTextAttributes = nil
    }

    func getNewsVC(_ postType: HNScraper.Page) -> UIViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewsNav")
        guard let newsVCNav = vc as? AppNavigationController else { fatalError() }
        guard let newsVC = newsVCNav.topViewController as? NewsViewController else { fatalError() }

        newsVC.title = postType.description

        newsVC.postType = postType

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
