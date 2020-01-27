//
//  Decoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "PKDecoder")
public typealias NKDecoder = PKDecoder

public protocol PKDecoder {
    
    associatedtype Input
    
    func decode<T: Decodable>(_ type: T.Type, from: Input) throws -> T 
}
