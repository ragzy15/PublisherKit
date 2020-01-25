//
//  Debounce.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
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
            
            var outputCounter = 0
            
            var newOutput: Output?
            
            var upstreamSubscriber: SameUpstreamFailureOperatorSink<S, Upstream>!
            
            upstreamSubscriber = .init(downstream: subscriber) { (output) in
                
                newOutput = output
                
                outputCounter += 1
                
                self.scheduler.schedule(after: self.dueTime) {
                    
                    guard !upstreamSubscriber.isCancelled else { return }
                    
                    outputCounter -= 1

                    guard outputCounter <= 0 else { return }
                    
                    _ = subscriber.receive(newOutput!)
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
