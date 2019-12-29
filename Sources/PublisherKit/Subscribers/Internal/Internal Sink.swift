//
//  Internal Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

class InternalSink<Downstream: NKSubscriber, Input, Failure: Error>: NKSubscribers.Sinkable, NKSubscriber {
    
    var downstream: Downstream?
    
    init(downstream: Downstream) {
        self.downstream = downstream
        super.init()
    }
    
    func receive(subscription: NKSubscription) {
        guard !isCancelled else { return }
        self.subscription = subscription
    }
    
    func receive(_ input: Input) -> NKSubscribers.Demand {
        guard !isCancelled else { return .none }
        return demand
    }
    
    func receive(completion: NKSubscribers.Completion<Failure>) {
        guard !isCancelled else { return }
    }
}
