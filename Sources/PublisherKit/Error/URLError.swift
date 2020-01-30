//
//  URLError.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

extension URLError {
    
    static func badURL() -> Error {
        let error = URLError(.badURL, userInfo: [
            NSURLErrorFailingURLStringErrorKey: "nil",
            NSLocalizedDescriptionKey: "Invalid URL"
        ])
        return error
    }
    
    static func badServerResponse() -> Error {
        let error = URLError(.badServerResponse, userInfo: [
            NSLocalizedDescriptionKey: "Bad server response)"
        ])
        return error
    }
    
    static func resourceUnavailable(for url: URL? = nil) -> Error {
        let error = URLError(.resourceUnavailable, userInfo: [
            NSLocalizedDescriptionKey: "A requested resource couldn’t be retrieved)."
        ])
        
        return error
    }
    
    static func zeroByteResource(for url: URL? = nil) -> Error {
        let error = URLError(.zeroByteResource, userInfo: [
            NSLocalizedDescriptionKey: "A server reported that a URL has a non-zero content length, but terminated the network connection gracefully without sending any data."
        ])
        
        return error
    }
    
    static func cannotDecodeContentData(for url: URL? = nil) -> Error {
        let error = URLError(.cannotDecodeContentData, userInfo: [
            NSLocalizedDescriptionKey: "Content data received during a connection request had an unknown content encoding."
        ])
        
        return error
    }
    
    static func cannotDecodeRawData(for url: URL? = nil) -> Error {
        let error = URLError(.cannotDecodeRawData, userInfo: [
            NSLocalizedDescriptionKey: "Content data received during a connection request had an unknown content encoding."
        ])
        
        return error
    }
}
