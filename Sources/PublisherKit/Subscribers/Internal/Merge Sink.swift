//
//  Merge Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKSubscribers {
    
    class MergeSink<Downstream: PKSubscriber, Upstream: PKPublisher>: Sinkable<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        var subscriptions: [PKSubscription] = []
        
        override func receive(subscription: PKSubscription) {
            guard !isCancelled else { return }
            subscriptions.append(subscription)
        }
        
        override func receive(_ input: Upstream.Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Upstream.Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
            end()
        }
        
        override func end() {
            super.end()
            subscriptions.removeAll()
        }
    }
}
