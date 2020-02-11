//
//  Merge Many.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension Publishers {
    
    public struct MergeMany<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        public let publishers: [Upstream]
        
        private let publisherCount: Int
        
        public init(_ upstream: Upstream...) {
            publishers = upstream
            publisherCount = publishers.count
        }
        
        public init<S: Swift.Sequence>(_ upstream: S) where Upstream == S.Element {
            publishers = upstream.map { $0 }
            publisherCount = publishers.count
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let mergeSubscriber = Inner(downstream: subscriber, publisherCount: publisherCount)
            
            publishers.forEach { (publisher) in
                publisher.subscribe(mergeSubscriber)
            }
        }
        
        public func merge(with other: Upstream) -> Publishers.MergeMany<Upstream> {
            Publishers.MergeMany(publishers + [other])
        }
    }
}

extension Publishers.MergeMany {

    // MARK: MERGE ALL SINK
    final class Inner<Downstream: Subscriber>: Subscribers.Inner<Downstream, Upstream.Output, Upstream.Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let publisherCount: Int
        private var completedCount: Int = 0
        
        init(downstream: Downstream, publisherCount: Int) {
            self.publisherCount = publisherCount
            super.init(downstream: downstream)
        }
        
        override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            guard status.isSubscribed else { return }
            
            guard let error = completion.getError() else {
                completedCount += 1
                if completedCount == publisherCount {
                    end {
                        downstream?.receive(completion: .finished)
                    }
                }
                return
            }
            
            end {
                downstream?.receive(completion: .failure(error))
            }
        }
        
        
        override var description: String {
            "Merge Many"
        }
    }
}
