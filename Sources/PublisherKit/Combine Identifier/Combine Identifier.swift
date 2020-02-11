//
//  Combine Identifier.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

import PublisherKitHelpers

public struct CombineIdentifier: Hashable, CustomStringConvertible {
    
    private let identifier: UInt64

    public init() {
        identifier = _newCombineIdentifier()
    }

    public init(_ obj: AnyObject) {
        identifier = UInt64(UInt(bitPattern: ObjectIdentifier(obj)))
    }
    
    public var description: String {
        "0x\(String(identifier, radix: 16))"
    }
}