//
//  Debounce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

public extension PKPublishers {
    
    struct Debounce<Upstream: PKPublisher, Scheduler: PKScheduler>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        public let dueTime: SchedulerTime
        
        public let scheduler: Scheduler
        
        public init(upstream: Upstream, dueTime: SchedulerTime, on scheduler: Scheduler) {
            self.upstream = upstream
            self.dueTime = dueTime
            self.scheduler = scheduler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let debounceSubscriber = InternalSink(downstream: subscriber, scheduler: scheduler, dueTime: dueTime)
            
            subscriber.receive(subscription: debounceSubscriber)
            debounceSubscriber.request(.unlimited)
            upstream.subscribe(debounceSubscriber)
        }
    }
}

extension PKPublishers.Debounce {
    
    // MARK: DEBOUNCE SINK
    private final class InternalSink<Downstream: PKSubscriber, Scheduler: PKScheduler>: UpstreamInternalSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var outputCounter = 0
        
        private var newOutput: Output?
        
        private let dueTime: SchedulerTime
        
        private let scheduler: Scheduler
        
        init(downstream: Downstream, scheduler: Scheduler, dueTime: SchedulerTime) {
            self.scheduler = scheduler
            self.dueTime = dueTime
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            
            newOutput = input
            
            outputCounter += 1
            
            scheduler.schedule(after: dueTime) { [weak self] in
                guard let `self` = self, !self.isCancelled else { return }
                
                self.outputCounter -= 1
                
                guard self.outputCounter <= 0, let output = self.newOutput else { return }
                
                self.downstream?.receive(input: output)
            }
            
            return demand
        }
    }
}
