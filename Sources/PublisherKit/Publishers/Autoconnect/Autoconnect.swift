//
//  Autoconnect.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 11/03/20.
//

extension Publishers {
    
    /// A publisher that automatically connects and disconnects from this connectable publisher.
    public class Autoconnect<Upstream: ConnectablePublisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        final public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let autoconnectSubscriber = Inner(downstream: subscriber)
            
            upstream.subscribe(autoconnectSubscriber)
            subscriber.receive(subscription: autoconnectSubscriber)
            
            autoconnectSubscriber.cancellable = upstream.connect()
        }
    }
}

extension Publishers.Autoconnect {
    
    // MARK: AUTOCONNECT SINK
    private final class Inner<Downstream: Subscriber>: Subscribers.Inner<Downstream, Upstream.Output, Upstream.Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        fileprivate var cancellable: Cancellable?
        
        override func cancel() {
            super.cancel()
            cancellable?.cancel()
            cancellable = nil
        }
        
       override var description: String {
            switch status {
            case .subscribed(let subscription):
                return "\(subscription)"
                
            default:
                return "Autoconnect"
            }
        }
    }
}
