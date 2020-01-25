//
//  Sinkable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKSubscribers {
    
    class DataTaskSinkable: Sinkable {
        
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
    
    class Sinkable: Hashable, PKSubscription {
        
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
        
        static func == (lhs: Sinkable, rhs: Sinkable) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid.uuidString + "\(date)")
        }
    }
}
