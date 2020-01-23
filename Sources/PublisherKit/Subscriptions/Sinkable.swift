//
//  Sinkable.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKSubscribers {
    
    class DataTaskSinkable: Sinkable {
        
        var task: URLSessionTask?
        
        deinit {
            print("Deiniting DataTaskSinkable")
        }
        
        override func cancel() {
            task?.cancel()
            super.cancel()
        }
        
        override final func end() {
            task = nil
            super.end()
        }
    }
    
    class Sinkable: Hashable, NKSubscription {
        
        private let uuid = UUID()
        private let date = Date()
        
        private(set) var isCancelled = false
        deinit {
            print("Deiniting Sinkable")
        }
        
        var isEnded = false
        
        var isOver: Bool {
            isEnded || isCancelled
        }
        
        var subscription: NKSubscription?
        
        var demand: NKSubscribers.Demand = .unlimited
        
        func request(_ demand: NKSubscribers.Demand) {
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
        
        final func getDemand() -> NKSubscribers.Demand {
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
