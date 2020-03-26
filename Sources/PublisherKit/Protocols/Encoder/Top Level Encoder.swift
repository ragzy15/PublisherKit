//
//  Top Level Encoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

public protocol TopLevelEncoder {
    
    associatedtype Output
    
    func encode<T: Encodable>(_ value: T) throws -> Output
}
