//
//  File.swift
//  
//
//  Created by Raghav Ahuja on 06/04/20.
//

import Foundation

extension Array where Element == URLQueryItem {
    
    var toDictionary: URLQuery {
        let params = Dictionary(uniqueKeysWithValues: self.map { ($0.name, $0.value) })
        return params
    }
}
