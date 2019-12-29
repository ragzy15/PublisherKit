//
//  NSObject PublisherType.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public protocol NSObjectPublisherType {
}

extension NSObjectPublisherType where Self: NSObject {
    
    public func nkPublisher<Value>(for keyPath: KeyPath<Self, Value>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.NKKeyValueObservingPublisher<Self, Value> {
        NSObject.NKKeyValueObservingPublisher(object: self, keyPath: keyPath, options: options)
    }
}
