//
//  Combine Identifier.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

import PublisherKitHelpers

public struct CombineIdentifier: Hashable, CustomStringConvertible {
    
    private let value: UInt64

    public init() {
        value = _newCombineIdentifier()
    }

    public init(_ obj: AnyObject) {
        value = UInt64(UInt(bitPattern: ObjectIdentifier(obj)))
    }
    
    public var description: String {
        "0x\(String(value, radix: 16))"
    }
}
