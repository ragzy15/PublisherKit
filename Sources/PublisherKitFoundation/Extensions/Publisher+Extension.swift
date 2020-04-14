//
//  File.swift
//  
//
//  Created by Raghav Ahuja on 06/04/20.
//

import PublisherKit
import Foundation

extension Publisher {
    
    /// Decodes the output from upstream using a specified `JSONDecoder`.
    ///
    /// - Parameter type: Type to decode into.
    /// - Parameter jsonKeyDecodingStrategy: JSON Key Decoding Strategy. Default value is `.useDefaultKeys`.
    /// - Parameter logOutput: Log output to console using `Logger`. Default value is `true`.
    public func decode<Item: Decodable>(type: Item.Type, jsonKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, logOutput: Bool = true) -> Publishers.Decode<Self, Item, JSONDecoder> {
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = jsonKeyDecodingStrategy
        
        var publisher = Publishers.Decode<Self, Item, JSONDecoder>(upstream: self, decoder: decoder)
        publisher.logOutput = logOutput
        
        return publisher
    }
}

extension Publisher where Output: Encodable {
    
    /// Encodes the output from upstream using a specified `TopLevelEncoder`.
    /// For example, use `JSONEncoder`.
    ///
    /// - Parameter keyEncodingStrategy: JSON Key Encoding Strategy. Default value is `.useDefaultKeys`.
    public func encodeJSON(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) -> Publishers.Encode<Self, JSONEncoder> {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        return Publishers.Encode(upstream: self, encoder: encoder)
    }
}
