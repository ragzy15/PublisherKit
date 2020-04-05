//
//  Top Level Decoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

public protocol TopLevelDecoder {
    
    associatedtype Input
    
    func decode<T: Decodable>(_ type: T.Type, from: Input) throws -> T
    
    /// Logs the input using serializer, eg. log JSON using JSONSerialization.
    /// - Parameter input: Input to serialize and log on console.
    func log(from input: Input)
}
