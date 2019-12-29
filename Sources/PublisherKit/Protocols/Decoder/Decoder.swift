//
//  Decoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public protocol NKDecoder {
    
    associatedtype Input
    
    func decode<T: Decodable>(_ type: T.Type, from: Self.Input) throws -> T 
}
