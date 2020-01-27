//
//  Subscription Sinkable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKSubscribers {
    
    class DataTaskSubscriptionSinkable: SubscriptionSinkable {
        
        var task: URLSessionTask?
        
        override func cancel() {
            task?.cancel()
            super.cancel()
        }
        
        override final func end() {
            task = nil
            super.end()
        }
    }
    
    class SubscriptionSinkable: Hashable, PKSubscription {
        
        private let uuid = UUID()
        private let date = Date()
        
        private(set) var isCancelled = false
        
        var isEnded = false
        
        var isOver: Bool {
            isEnded || isCancelled
        }
        
        var subscription: PKSubscription?
        
        var demand: PKSubscribers.Demand = .unlimited
        
        func request(_ demand: PKSubscribers.Demand) {
            self.demand = demand
        }
        
        public func cancel() {
            isCancelled = true
            subscription?.cancel()
            subscription = nil
        }
        
        func end() {
            isEnded = true
            subscription = nil
        }
        
        final func getDemand() -> PKSubscribers.Demand {
            if demand == .unlimited { return demand }
            else if demand == .none { return .none }
            else { return demand - 1 }
        }
        
        static func == (lhs: SubscriptionSinkable, rhs: SubscriptionSinkable) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid.uuidString + "\(date)")
        }
    }
}
