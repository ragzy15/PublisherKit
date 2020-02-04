//
//  Subscription Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

class SubscriptionSink: Subscription {
    
    private(set) var isCancelled = false
    
    private(set) var isEnded = false
    
    var isOver: Bool {
        isEnded || isCancelled
    }
    
    var subscription: Subscription?
    
    var demand: Subscribers.Demand = .unlimited
    
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
    }
    
    func cancel() {
        isCancelled = true
        subscription?.cancel()
        subscription = nil
    }
    
    func end() {
        isEnded = true
        subscription = nil
    }
    
    final func getDemand() -> Subscribers.Demand {
        demand -= 1
        return demand
    }
}
