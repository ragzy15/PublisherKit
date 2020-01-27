//
//  TableViewController.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 23/01/20.
//

import UIKit

final class TableViewController: UITableViewController {
    
    private let viewModel = UsersViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.diffableDatasource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, user) -> UITableViewCell? in
            
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell.textLabel?.text = user.name
            return cell
        })
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteUser(at: indexPath)
        }
    }
    
    @IBAction private func addRandomButtonTapped(_ sender: Any) {
        viewModel.fetchRandomUsers()
    }
    
    @IBAction private func addButtonTapped(_ sender: UIBarButtonItem) {
        guard let vc = storyboard?.instantiateViewController(identifier: "AddUserVC") as? AddUserViewController else {
            return
        }
        let addUserViewModel = AddUserViewModel(onSubmit: viewModel.insert)
        vc.viewModel = addUserViewModel
        
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        present(nav, animated: true)
    }
}
