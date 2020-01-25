//
//  User.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//  Copyright © 2020 Raghav Ahuja. All rights reserved.
//

import Foundation

struct User: Codable, Hashable {
    let id, createdAt: String?
    var name, avatar: String?
    var email: String?
}

typealias Users = [User]
