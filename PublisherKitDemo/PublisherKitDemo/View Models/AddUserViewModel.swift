//
//  AddUserViewModel.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//  Copyright © 2020 Raghav Ahuja. All rights reserved.
//

import Foundation
import PublisherKit

final class AddUserViewModel {
    
    private let onSubmit = BindableValue<User>(User(id: nil, createdAt: nil, name: nil, avatar: nil, email: nil))
    
    private var user = User(id: "\(Int.random(in: 100...1000))", createdAt: "\(Date())", name: nil, avatar: nil, email: nil)
    
    init(onSubmit: @escaping (User) -> Void) {
        self.onSubmit.bind(to: onSubmit)
    }
    
    func updateName(_ name: String) {
        user.name = name
    }
    
    func updateAvatar(_ avatar: String) {
        user.avatar = avatar
    }
    
    func updateEmail(_ email: String) {
        user.email = email
    }
    
    func submit() {
        onSubmit.send(user)
    }
}
