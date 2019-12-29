//
//  Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKSubscribers {

    /// A simple subscriber that requests an unlimited number of values upon subscription.
    final class Sink<Input, Failure: Error>: NKSubscriber, NKCancellable {

        /// The closure to execute on receipt of a value.
        final public let receiveValue: (Input) -> Void

        /// The closure to execute on completion.
        final public let receiveCompletion: (NKSubscribers.Completion<Failure>) -> Void
        
        private var subscription: NKSubscription?
        
        var isCancelled = false

        public init(receiveCompletion: @escaping ((NKSubscribers.Completion<Failure>) -> Void), receiveValue: @escaping ((Input) -> Void)) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }

        final public func receive(subscription: NKSubscription) {
            guard !isCancelled else { return }
            self.subscription = subscription
        }

        final public func receive(_ value: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(value)
            return .unlimited
        }

        final public func receive(completion: NKSubscribers.Completion<Failure>) {
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
