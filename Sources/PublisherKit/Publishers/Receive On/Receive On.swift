//
//  Receive On.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers {
    
    public struct ReceiveOn<Upstream: PKPublisher>: PKPublisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        public let scheduler: PKScheduler
        
        public init(upstream: Upstream, on scheduler: PKScheduler) {
            self.upstream = upstream
            self.scheduler = scheduler
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = UpstreamOperatorSink<S, Upstream>(downstream: subscriber, receiveCompletion: { (completion) in

                self.scheduler.schedule {
                    subscriber.receive(completion: completion)
                }
                
            }) { (output) in
                
                self.scheduler.schedule {
                    _ = subscriber.receive(output)
                }
                
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
