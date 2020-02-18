//
//  Publisher Compatible.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

@available(*, deprecated, renamed: "PublisherCompatible")
typealias NSObjectPKPublisher = PublisherCompatible

public protocol PublisherCompatible {
}

extension PublisherCompatible where Self: NSObject {
    
    public func pkPublisher<Value>(for keyPath: KeyPath<Self, Value>, options: NSKeyValueObservingOptions = [.initial, .new]) -> NSObject.KeyValueObservingPKPublisher<Self, Value> {
        NSObject.KeyValueObservingPKPublisher(object: self, keyPath: keyPath, options: options)
    }
}
