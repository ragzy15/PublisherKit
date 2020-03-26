//
//  __KeyValueObservingPKPublisher.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

public protocol __KeyValueObservingPKPublisher { }

extension __KeyValueObservingPKPublisher where Self: NSObject {
    
    public func pkPublisher<Value>(for keyPath: KeyPath<Self, Value>, options: NSKeyValueObservingOptions = [.initial, .new]) -> KeyValueObservingPKPublisher<Self, Value> {
        KeyValueObservingPKPublisher(object: self, keyPath: keyPath, options: options)
    }
}
