//
//  Debounce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension Publishers {
    
    /// A publisher that publishes elements only after a specified time interval elapses after receiving an element from upstream publisher, using the specified scheduler.
    struct Debounce<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// Time the publisher should wait before publishing an element.
        public let dueTime: SchedulerTime
        
        /// The scheduler on which elements are published.
        public let scheduler: Context
        
        public init(upstream: Upstream, dueTime: SchedulerTime, on scheduler: Context) {
            self.upstream = upstream
            self.dueTime = dueTime
            self.scheduler = scheduler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let debounceSubscriber = InternalSink(downstream: subscriber, scheduler: scheduler, dueTime: dueTime)
            upstream.subscribe(debounceSubscriber)
        }
    }
}

extension Publishers.Debounce {
    
    // MARK: DEBOUNCE SINK
    private final class InternalSink<Downstream: Subscriber, Context: Scheduler>: UpstreamInternalSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var outputCounter = 0
        
        private var newOutput: Output?
        
        private let dueTime: SchedulerTime
        
        private let scheduler: Context
        
        init(downstream: Downstream, scheduler: Context, dueTime: SchedulerTime) {
            self.scheduler = scheduler
            self.dueTime = dueTime
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Output) -> Subscribers.Demand {
            guard !isCancelled else { return .none }
            
            newOutput = input
            
            outputCounter += 1
            
            scheduler.schedule(after: dueTime) { [weak self] in
                guard let `self` = self, !self.isCancelled else { return }
                
                self.outputCounter -= 1
                
                guard self.outputCounter <= 0, let output = self.newOutput else { return }
                
                _ = self.downstream?.receive(output)
            }
            
            return demand
        }
    }
}
