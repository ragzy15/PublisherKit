//
//  Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

public extension Subscribers {

    /// A simple subscriber that requests an unlimited number of values upon subscription.
    final class Sink<Input, Failure: Error>: Subscriber, Cancellable {

        /// The closure to execute on receipt of a value.
        final public let receiveValue: (Input) -> Void

        /// The closure to execute on completion.
        final public let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
        
        private var subscription: Subscription?
        
        var isCancelled = false

        public init(receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Input) -> Void)) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }

        final public func receive(subscription: Subscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
            subscription.request(.unlimited)
        }

        final public func receive(_ value: Input) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(value)
            return .unlimited
        }

        final public func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            receiveCompletion(completion)
            end()
        }

        final public func cancel() {
            isCancelled = true
            subscription?.cancel()
            subscription = nil
        }
        
        final func end() {
            subscription?.cancel()
            subscription = nil
        }
    }
}
