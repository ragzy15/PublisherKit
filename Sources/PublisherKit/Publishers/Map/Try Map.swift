//
//  Try Map.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension PKPublishers {
    
    struct TryMap<Upstream: PKPublisher, Output>: PKPublisher {
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        /// The closure that transforms elements from the upstream publisher.
        public let transform: (Upstream.Output) throws -> Output
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            typealias Subscriber = PKSubscribers.OperatorSink<S, Upstream.Output, Failure>
            
            let upstreamSubscriber = Subscriber(downstream: subscriber, receiveCompletion: { (completion) in
                
                subscriber.receive(completion: completion)
                
            }) { (output) in
               do {
                   let newOutput = try self.transform(output)
                   _ = subscriber.receive(newOutput)
                   
               } catch {
                   subscriber.receive(completion: .failure(error))
               }
            }
            
            let bridgeSubscriber = PKSubscribers.OperatorSink<Subscriber, Upstream.Output, Upstream.Failure>(downstream: upstreamSubscriber, receiveCompletion: { (completion) in
                
                let newCompletion = completion.mapError { $0 as Failure }
                upstreamSubscriber.receive(completion: newCompletion)
                
            }) { (output) in
                _ = upstreamSubscriber.receive(output)
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            bridgeSubscriber.request(.unlimited)
            upstream.receive(subscriber: bridgeSubscriber)
        }
    }
}

extension PKPublishers.TryMap {
    
    public func map<T>(_ transform: @escaping (Output) -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = try self.transform(output)
            return transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
    
    public func tryMap<T>(_ transform: @escaping (Output) throws -> T) -> PKPublishers.TryMap<Upstream, T> {
        
        let newTransform: (Upstream.Output) throws -> T = { output in
            let newOutput = try self.transform(output)
            return try transform(newOutput)
        }
        
        return PKPublishers.TryMap<Upstream, T>(upstream: upstream, transform: newTransform)
    }
}
