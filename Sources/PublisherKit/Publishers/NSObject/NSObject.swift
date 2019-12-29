//
//  NSObject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NSObject: NSObjectPublisherType {
}

extension NSObject {
    

    /// A publisher that emits events when the value of a KVO-compliant property changes.
    public struct NKKeyValueObservingPublisher<Subject: NSObject, Value>: Equatable, NKPublisher {
         
        public typealias Output = Value
        
        public typealias Failure = Never
        
        public let object: Subject

        public let keyPath: KeyPath<Subject, Value>

        public let options: NSKeyValueObservingOptions

        public init(object: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
            self.object = object
            self.keyPath = keyPath
            self.options = options
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let nsObjectSubscriber = NKSubscribers.TopLevelSink<S, Self>(downstream: subscriber)
            
            let observer = object.observe(keyPath, options: options) { (object, valueChange) in
                if let oldValue = valueChange.oldValue {
                    nsObjectSubscriber.receive(input: oldValue)
                }
                
                if let newValue = valueChange.newValue {
                    nsObjectSubscriber.receive(input: newValue)
                }
            }
            
            nsObjectSubscriber.cancelBlock = {
                observer.invalidate()
            }
            
            subscriber.receive(subscription: nsObjectSubscriber)
        }
        
        public static func == (lhs: NSObject.NKKeyValueObservingPublisher<Subject, Value>, rhs: NSObject.NKKeyValueObservingPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}
