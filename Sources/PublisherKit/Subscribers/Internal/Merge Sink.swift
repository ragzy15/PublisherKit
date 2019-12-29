//
//  Merge Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKSubscribers {
    
    class MergeSink<Downstream: NKSubscriber, Upstream: NKPublisher>: InternalSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure {
        
        var subscriptions: [NKSubscription] = []
        
        override func receive(subscription: NKSubscription) {
            guard !isCancelled else { return }
            subscriptions.append(subscription)
        }
        
        override func receive(_ input: Upstream.Output) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: NKSubscribers.Completion<Upstream.Failure>) {
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
