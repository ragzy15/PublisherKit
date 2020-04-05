//
//  Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Subscribers {
    
    /// A simple subscriber that requests an unlimited number of values upon subscription.
    public final class Sink<Input, Failure: Error>: Subscriber, Cancellable, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
        
        /// The closure to execute on receipt of a value.
        final public let receiveValue: (Input) -> Void
        
        /// The closure to execute on completion.
        final public let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
        
        private var status: SubscriptionStatus = .awaiting
        
        public init(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Input) -> Void)) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }
        
        final public func receive(subscription: Subscription) {
            guard case .awaiting = status else {
                subscription.cancel()
                return
            }
            
            status = .subscribed(to: subscription)
            subscription.request(.unlimited)
        }
        
        final public func receive(_ value: Input) -> Subscribers.Demand {
            receiveValue(value)
            return .none
        }
        
        final public func receive(completion: Subscribers.Completion<Failure>) {
            receiveCompletion(completion)
            status = .terminated
        }
        
        final public func cancel() {
            guard case .subscribed(let subscription) = status else { return }
            status = .terminated
            subscription.cancel()
        }
        
        final public var description: String {
            "Sink"
        }
        
        final public var playgroundDescription: Any {
            description
        }
        
        final public var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
