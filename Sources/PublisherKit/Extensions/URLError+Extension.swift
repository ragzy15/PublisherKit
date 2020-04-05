//
//  URLError.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

extension URLError {
    
    static func badServerResponse() -> Error {
        URLError(.badServerResponse, userInfo: [
            NSLocalizedDescriptionKey: "Bad server response."
        ])
    }
    
    static func cannotDecodeContentData() -> Error {
        URLError(.cannotDecodeContentData, userInfo: [
            NSLocalizedDescriptionKey: "Content data received during a connection request had an unknown content encoding."
        ])
    }
}
