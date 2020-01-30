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
            
            let nsObjectSubscriber = InternalSink(downstream: subscriber, object: object, keyPath: keyPath, options: options)
            
            nsObjectSubscriber.observe()
            
            subscriber.receive(subscription: nsObjectSubscriber)
        }
        
        public static func == (lhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>, rhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}

extension NSObject.KeyValueObservingPKPublisher {
    
    // MARK: NSOBJECT SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.Sinkable<Downstream, Output, Failure> where Downstream.Failure == Failure, Downstream.Input == Output {
        
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
        
        override func receive(_ input: Value) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
        
        override func end() {
            observer?.invalidate()
            observer = nil
            super.end()
        }
        
        override func cancel() {
            observer?.invalidate()
            observer = nil
            super.cancel()
        }
    }
}
