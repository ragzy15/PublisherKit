//
//  NSObject PublisherType.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public protocol NSObjectPKPublisher {
}

extension NSObjectPKPublisher where Self: NSObject {
    
    public func pkPublisher<Value>(for keyPath: KeyPath<Self, Value>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.KeyValueObservingPKPublisher<Self, Value> {
        NSObject.KeyValueObservingPKPublisher(object: self, keyPath: keyPath, options: options)
    }
}
