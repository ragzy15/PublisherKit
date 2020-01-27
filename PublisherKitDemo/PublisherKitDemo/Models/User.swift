//
//  User.swift
//  PublisherKit+Example
//
//  Created by Raghav Ahuja on 25/01/20.
//

import Foundation

struct User: Codable, Hashable {
    let id, createdAt: String?
    var name, avatar: String?
    var email: String?
}

typealias Users = [User]
