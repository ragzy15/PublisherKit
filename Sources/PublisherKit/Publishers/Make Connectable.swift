//
//  Make Connectable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that provides explicit connectability to another publisher.
    ///
    /// Call connect() on this publisher when you want to attach to its upstream publisher.
    public struct MakeConnectable<Upstream: Publisher>: ConnectablePublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        private let inner: Multicast<Upstream, PassthroughSubject<Output, Failure>>
        
        public init(upstream: Upstream) {
            inner = upstream.multicast(subject: PassthroughSubject())
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            inner.subscribe(subscriber)
        }
        
        public func connect() -> Cancellable {
            inner.connect()
        }
    }
}
