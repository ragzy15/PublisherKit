//
//  NSObject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension NSObject: NSObjectPKPublisher {
}

extension NSObject {
    

    /// A publisher that emits events when the value of a KVO-compliant property changes.
    public struct KeyValueObservingPKPublisher<Subject: NSObject, Value>: Equatable, PKPublisher {
         
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let nsObjectSubscriber = InternalSink(downstream: subscriber)
            
            nsObjectSubscriber.observer = object.observe(keyPath, options: options) { (object, valueChange) in
                
                if let oldValue = valueChange.oldValue {
                    nsObjectSubscriber.receive(input: oldValue)
                }
                
                if let newValue = valueChange.newValue {
                    nsObjectSubscriber.receive(input: newValue)
                }
            }
            
            subscriber.receive(subscription: nsObjectSubscriber)
        }
        
        public static func == (lhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>, rhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}
