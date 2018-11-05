//
//  LeaderboardTableViewController.swift
//  Hackers
//
//  Created by Robert Trencheny on 11/4/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class LeaderboardTableViewController: UITableViewController {

    var board: [HNLeader]?

    var selectedLeader: HNUser?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTheming()

        HTMLDataSource().GetLeaders().done { leaders in
            self.board = leaders
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.board?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "leaderCell", for: indexPath)

        cell.textLabel?.textColor = AppThemeProvider.shared.currentTheme.textColor
        cell.textLabel?.font = UIFont.mySystemFont(ofSize: 18.0)

        cell.detailTextLabel?.textColor = AppThemeProvider.shared.currentTheme.textColor
        cell.detailTextLabel?.font = UIFont.mySystemFont(ofSize: 18.0)

        cell.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor

        guard let board = self.board else { return cell }

        let leader = board[indexPath.row]

        cell.textLabel?.text = String(leader.Rank) + ". " + leader.User.Username
        cell.textLabel?.textColor = leader.User.Color
        if let karma = leader.Karma {
            cell.detailTextLabel?.text = String(karma)
        } else {
            cell.detailTextLabel?.text = "?????"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let board = self.board else { return }

        let leader = board[indexPath.row]

        self.selectedLeader = leader.User

        self.performSegue(withIdentifier: "LeaderProfile", sender: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

        if segue.identifier == "LeaderProfile", let vc = segue.destination as? ProfileViewController {
            vc.user = self.selectedLeader
            self.selectedLeader = nil
        }
    }

}

extension LeaderboardTableViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
