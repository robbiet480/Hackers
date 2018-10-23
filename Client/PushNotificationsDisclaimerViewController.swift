//
//  PushNotificationsDisclaimerViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/23/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

final class PushNotificationsDisclaimerViewController: UIViewController {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(onDone)
        )
        title = NSLocalizedString("Push Notifications", comment: "")

        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: 15,
            bottom: 15,
            right: 15
        )
        textView.isEditable = false

        textView.textColor = .black
        textView.text = NSLocalizedString("Hackers uses iOS background fetch to periodically check (about every 10-15 minutes) for new Hacker News stories. When there is a new story that meets your minimum points threshold available, Hacker News sends alerts with local notifications.\n\nThis setup requires Background App Refresh to be enabled to work. Enable this feature in Settings > General > Background App Refresh.\n\nHackers is a open source project with no financial backing and real-time push notifications would incur significant server costs.", comment: "")
        view.addSubview(textView)

        preferredContentSize = textView.sizeThatFits(CGSize(
            width: min(320, UIScreen.main.bounds.width - 16),
            height: CGFloat.greatestFiniteMagnitude
        ))
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textView.frame = view.bounds
    }

    @objc private func onDone() {
        dismiss(animated: true)
    }

}
