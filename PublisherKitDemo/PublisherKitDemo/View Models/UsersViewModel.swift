//
//  UsersViewModel.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//  Copyright © 2020 Raghav Ahuja. All rights reserved.
//

import UIKit
import PublisherKit

final class UsersViewModel {
    
    private var cancellables = PKCancellables()
    
    private let url = URL(string: "https://5da1e9ae76c28f0014bbe25f.mockapi.io/users")!
    
    var diffableDatasource: UITableViewDiffableDataSource<Int, User>!
    
    private var users: Users = []
    
    func fetchRandomUsers() {
        URLSession.shared.dataTaskPKPublisher(for: url, name: "FETCH ALL USERS")
            .map(\.data)
            .decode(type: Users.self, jsonKeyDecodingStrategy: .useDefaultKeys)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (users) in
                self?.append(newUsers: users)
        }
        .store(in: &cancellables)
    }
    
    func insert(_ user: User) {
        users.insert(user, at: 0)
        apply()
    }
    
    func append(newUsers: Users) {
        users.append(contentsOf: newUsers)
        apply()
    }
    
    func deleteUser(at indexPath: IndexPath) {
        guard diffableDatasource.itemIdentifier(for: indexPath) != nil else {
            return
        }
        
        users.remove(at: indexPath.row)
        apply()
    }
    
    private func apply() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, User>()
        snapshot.appendSections([0])
        snapshot.appendItems(users)
        diffableDatasource?.apply(snapshot, animatingDifferences: true, completion: nil)
    }
}
