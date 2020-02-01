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
        
        /// The object that contains the property to observe.
        public let object: Subject
        
        /// The key path of a property to observe.
        public let keyPath: KeyPath<Subject, Value>
        
        /// The observing options for the property.
        public let options: NSKeyValueObservingOptions
        
        public init(object: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
            self.object = object
            self.keyPath = keyPath
            self.options = options
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let nsObjectSubscriber = InternalSink(downstream: subscriber, object: object, keyPath: keyPath, options: options)
            subscriber.receive(subscription: nsObjectSubscriber)
            
            nsObjectSubscriber.observe()
        }
        
        public static func == (lhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>, rhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}

extension NSObject.KeyValueObservingPKPublisher {
    
    // MARK: NSOBJECT SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.OperatorSink<Downstream, Output, Failure> where Downstream.Failure == Failure, Downstream.Input == Output {
        
        private var observer: NSKeyValueObservation?
        
        private var object: Subject?
        
        private let keyPath: KeyPath<Subject, Value>
        
        private let options: NSKeyValueObservingOptions
        
        init(downstream: Downstream, object: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
            self.object = object
            self.keyPath = keyPath
            self.options = options
            super.init(downstream: downstream)
        }
        
        func observe() {
            observer = object?.observe(keyPath, options: options) { [weak self] (object, valueChange) in
                
                if let oldValue = valueChange.oldValue {
                    self?.receive(input: oldValue)
                }
                
                if let newValue = valueChange.newValue {
                    self?.receive(input: newValue)
                }
            }
        }
        
        func receive(input: Value) {
            guard !isCancelled else { return }
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
        }
        
        override func end() {
            observer?.invalidate()
            observer = nil
            object = nil
            super.end()
        }
        
        override func cancel() {
            observer?.invalidate()
            observer = nil
            object = nil
            super.cancel()
        }
    }
}
