//
//  Encoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

import Foundation

public protocol PKEncoder {
    
    associatedtype Output

    func encode<T: Encodable>(_ value: T) throws -> Output
}
