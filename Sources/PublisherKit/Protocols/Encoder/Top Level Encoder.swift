//
//  Top Level Encoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

@available(*, deprecated, renamed: "TopLevelEncoder")
public typealias PKEncoder = TopLevelEncoder

public protocol TopLevelEncoder {
    
    associatedtype Output

    func encode<T: Encodable>(_ value: T) throws -> Output
}
