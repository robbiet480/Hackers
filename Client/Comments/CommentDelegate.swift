//
//  CommentDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 01/09/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

protocol CommentDelegate {
    func commentTapped(_ sender: UITableViewCell)
    func linkTapped(_ URL: URL, sender: UITextView)
    func commentLongPressed(_ sender: UITableViewCell)
    func authorTapped(_ user: HNUser)
}
