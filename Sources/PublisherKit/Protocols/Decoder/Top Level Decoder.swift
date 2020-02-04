//
//  Top Level Decoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

@available(*, deprecated, renamed: "TopLevelDecoder")
public typealias NKDecoder = TopLevelDecoder

@available(*, deprecated, renamed: "TopLevelDecoder")
public typealias PKDecoder = TopLevelDecoder

public protocol TopLevelDecoder {
    
    associatedtype Input
    
    func decode<T: Decodable>(_ type: T.Type, from: Input) throws -> T 
}
