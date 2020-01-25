//
//  Encode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/01/20.
//

import Foundation

public extension PKPublishers {
    
    struct Encode<Upstream: PKPublisher, Encoder: PKEncoder>: PKPublisher where Upstream.Output: Encodable {
        
        public typealias Output = Encoder.Output
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        private let encoder: Encoder
        
        public init(upstream: Upstream, encoder: Encoder) {
            self.upstream = upstream
            self.encoder = encoder
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = UpstreamOperatorSink<S, Upstream>(downstream: subscriber, receiveCompletion: { (completion) in
                
                let completion = completion.mapError { $0 as Error }
                subscriber.receive(completion: completion)
                
            }) { (output) in
                
                do {
                    let newOutput = try self.encoder.encode(output)
                    _ = subscriber.receive(newOutput)
                    
                } catch {
                    subscriber.receive(completion: .failure(error))
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.unlimited)
            upstream.subscribe(upstreamSubscriber)
        }
    }
}
