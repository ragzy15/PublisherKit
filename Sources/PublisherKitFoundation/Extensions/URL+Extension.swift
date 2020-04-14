//
//  URL+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

typealias URLQuery = [String: String?]
extension URL {
    
    var parameters: URLQuery {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return [:]
        }
        return components.queryItems?.toDictionary ?? [:]
    }
}
