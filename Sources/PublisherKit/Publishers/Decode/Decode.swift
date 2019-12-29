//
//  Decode.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension NKPublishers {
    
    struct Decode<Upstream: NKPublisher, Item: Decodable, Decoder: NKDecoder>: NKPublisher where Upstream.Output == Decoder.Input {
        
        public typealias Output = Item
        
        public typealias Failure = Error
        
        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream
        
        private let decoder: Decoder
        
        public var log = false
        
        public init(upstream: Upstream, decoder: Decoder) {
            self.upstream = upstream
            self.decoder = decoder
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = UpstreamOperatorSink<S, Upstream>(downstream: subscriber, receiveCompletion: { (completion) in
                
                let completion = completion.mapError { $0 as Error }
                subscriber.receive(completion: completion)
                
            }) { (output) in
                
                do {
                    let newOutput = try self.decoder.decode(Item.self, from: output)
                    
                    #if DEBUG
                    if self.log {
                        Logger.default.printJSON(data: output, apiName: "")
                    }
                    #endif
                    
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
