//
//  SubmitViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/2/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka
import StatusAlert
import FontAwesome_swift

class SubmitViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()

        SegmentedRow<String>.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        SegmentedRow<String>.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        URLRow.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        URLRow.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        TextAreaRow.defaultCellSetup = AppThemeProvider.shared.eurekaCellUpdate
        TextAreaRow.defaultCellUpdate = AppThemeProvider.shared.eurekaCellUpdate

        self.title = "New Post"

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self, action: #selector(cancel(_:)))

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self,
                                                                 action: #selector(submit(_:)))

        self.form
            +++ Section(header: "Title", footer: "")
                <<< TextRow("title"){
                    $0.add(rule: RuleMaxLength(maxLength: 80))
                    $0.add(rule: RuleRequired())
                }
            +++ Section(header: "Content",
                        footer: "Leave URL blank to submit a question for discussion. If there is no URL, the Text (if any) will appear at the top of the thread.")
                <<< SegmentedRow<String>("type"){
                    $0.options = ["URL", "Text"]
                }.onChange {
                    if $0.value == "URL" {
                        self.form.setValues(["text": nil])
                    } else if $0.value == "Text" {
                        self.form.setValues(["url": nil])
                    }
                }
                <<< URLRow("url"){
                    $0.hidden = "$type != 'URL'"
                    $0.add(rule: RuleURL())
                }
                <<< TextAreaRow("text"){
                    $0.hidden = "$type != 'Text'"
                }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let row = self.form.rowBy(tag: "title") as? TextRow {
            row.cell.textField.becomeFirstResponder()
        }
    }

    @objc func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func submit(_ sender: UIBarButtonItem) {
        print("Submit post!")
 
        if let title = (self.form.rowBy(tag: "title") as! TextRow).value {
            let url = (self.form.rowBy(tag: "url") as! URLRow).value
            let text = (self.form.rowBy(tag: "text") as! TextAreaRow).value

            HNScraper.shared.Submit(title, url: url, text: text).done { newPost in
                print("newPost", newPost?.description)

                self.dismiss(animated: true, completion: {
                    let statusAlert = StatusAlert()
                    statusAlert.image = UIImage.fontAwesomeIcon(name: .thumbsUp, style: .solid, textColor: .black,
                                                                size: CGSize(width: 90, height: 90))
                    statusAlert.title = "Post created"
                    statusAlert.canBePickedOrDismissed = true

                    statusAlert.showInKeyWindow()
                })
            }.catch { error in
                print("Error when creating post", error)

                let statusAlert = StatusAlert()
                statusAlert.image = UIImage.fontAwesomeIcon(name: .timesCircle, style: .solid, textColor: .black,
                                                            size: CGSize(width: 90, height: 90))
                statusAlert.title = "Failed to create post"
                statusAlert.canBePickedOrDismissed = true

                statusAlert.showInKeyWindow()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SubmitViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor

        self.tableView.reloadData()
    }
}
