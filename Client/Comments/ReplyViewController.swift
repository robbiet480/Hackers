//
//  ReplyViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/2/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import FontAwesome_swift
import StatusAlert

class ReplyViewController: UIViewController {

    @IBOutlet weak var replyText: UITextView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    var replyingTo: HNItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        navigationBar.setValue(true, forKey: "hidesShadow")
    }
    @IBAction func postButton(_ sender: UIBarButtonItem) {
        print("Post comment with text", replyingTo?.ID, replyText.text)

        if let replyingTo = replyingTo, replyingTo.Type != .comment, let post = replyingTo as? HNPost {
            post.Reply(replyText.text).done { newComment in
                print("Reply to post generated new comment", newComment)
                self.success()
            }.catch { error in
                print("Received error when attempting to reply to post", error)

                self.failed()
            }
        } else if let replyingTo = replyingTo, replyingTo.Type == .comment, let comment = replyingTo as? HNComment {
            comment.Reply(replyText.text).done { newComment in
                print("Reply to comment generated new comment", newComment)
                self.success()
            }.catch { error in
                print("Received error when attempting to reply to comment", error)
                self.failed()
            }
        }
    }
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    func success() {
        self.dismiss(animated: true, completion: {
            let statusAlert = StatusAlert()
            statusAlert.image = UIImage.fontAwesomeIcon(name: .thumbsUp, style: .solid, textColor: .black,
                                                        size: CGSize(width: 90, height: 90))
            statusAlert.title = "Comment created"
            statusAlert.canBePickedOrDismissed = true

            statusAlert.showInKeyWindow()
        })
    }

    func failed() {
        let statusAlert = StatusAlert()
        statusAlert.image = UIImage.fontAwesomeIcon(name: .timesCircle, style: .solid, textColor: .black,
                                                    size: CGSize(width: 90, height: 90))
        statusAlert.title = "Failed to create comment"
        statusAlert.canBePickedOrDismissed = true

        statusAlert.showInKeyWindow()
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

extension ReplyViewController: Themed {
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
