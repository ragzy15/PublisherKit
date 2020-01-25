//
//  Internal Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

class InternalSink<Downstream: PKSubscriber, Input, Failure: Error>: PKSubscribers.Sinkable, PKSubscriber {
    
    var downstream: Downstream?
    
    init(downstream: Downstream) {
        self.downstream = downstream
        super.init()
    }
    
    func receive(subscription: PKSubscription) {
        guard !isCancelled else { return }
        self.subscription = subscription
    }
    
    func receive(_ input: Input) -> PKSubscribers.Demand {
        guard !isCancelled else { return .none }
        return demand
    }
    
    func receive(completion: PKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
    }
}
