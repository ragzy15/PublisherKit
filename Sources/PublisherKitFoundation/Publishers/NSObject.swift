//
//  NSObject.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import PublisherKit
import Foundation

extension NSObject {
    
    /// A publisher that emits events when the value of a KVO-compliant property changes.
    public struct KeyValueObservingPKPublisher<Subject: NSObject, Value>: Equatable, Publisher {
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subscriber.receive(subscription: KVOSubscription(downstream: AnySubscriber(subscriber), object: object, keyPath: keyPath, options: options))
        }
        
        public static func == (lhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>, rhs: NSObject.KeyValueObservingPKPublisher<Subject, Value>) -> Bool {
            lhs.keyPath == rhs.keyPath && lhs.options == rhs.options
        }
    }
}

extension NSObject: __KeyValueObservingPKPublisher {
    
    // MARK: NSOBJECT SINK
    private final class KVOSubscription<Subject: NSObject, Output, Failure: Error>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        private var observer: NSKeyValueObservation?
        
        private var object: Subject?
        
        private let keyPath: KeyPath<Subject, Output>
        
        private let options: NSKeyValueObservingOptions
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var downstream: AnySubscriber<Output, Failure>?
        private var demand: Subscribers.Demand = .none
        
        init(downstream: AnySubscriber<Output, Failure>, object: Subject, keyPath: KeyPath<Subject, Output>, options: NSKeyValueObservingOptions) {
            self.downstream = downstream
            self.object = object
            self.keyPath = keyPath
            self.options = options
        }
        
        func request(_ demand: Subscribers.Demand) {
            precondition(demand > .none, "Demand must not be zero.")
            
            lock.lock()
            guard observer == nil else { lock.unlock(); return }
            self.demand += demand
            lock.unlock()
            
            let observer = object?.observe(keyPath, options: options) { [weak self] (object, valueChange) in
                guard let `self` = self else { return }
                
                self.lock.lock()
                guard self.demand > .none else { self.lock.unlock(); return }
                self.demand -= 1
                self.lock.unlock()
                
                self.downstreamLock.lock()
                var additionalDemand: Subscribers.Demand = .none
                
                if let oldValue = valueChange.oldValue {
                    additionalDemand += self.downstream?.receive(oldValue) ?? .none
                }
                
                if let newValue = valueChange.newValue {
                    additionalDemand += self.downstream?.receive(newValue) ?? .none
                }
                self.downstreamLock.unlock()
                
                self.lock.lock()
                self.demand += additionalDemand
                self.lock.unlock()
            }
            
            lock.lock()
            self.observer = observer
            lock.unlock()
        }
        
        func cancel() {
            lock.lock()
            guard let observer = observer else { lock.unlock(); return }
            self.observer = nil
            object = nil
            downstream = nil
            lock.unlock()
            observer.invalidate()
        }
        
        var description: String {
            "KVOSubscription"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            let children: [Mirror.Child] = [
                ("observation", observer as Any),
                ("demand", demand)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
