//
//  Array+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension Array where Element == URLQueryItem {
    
    var toDictionary: URLQuery {
        let params = Dictionary(uniqueKeysWithValues: self.map { ($0.name, $0.value) })
        return params
    }
}
