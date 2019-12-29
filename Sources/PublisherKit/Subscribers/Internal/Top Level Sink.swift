//
//  Top Level Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKSubscribers {
    
    class TopLevelSink<Downstream: NKSubscriber, Publisher: NKPublisher>: SameOperatorSink<Downstream, Publisher.Output, Publisher.Failure> where Downstream.Input == Publisher.Output, Downstream.Failure == Publisher.Failure {
        
        private(set) var isCompleted: Bool = false
        
        var cancelBlock: (() -> Void)?
        
        func receive(input: Input) {
            _ = super.receive(input)
//            guard !isCancelled else { return }
//
//            if demand != .none {
//                _ = downstream?.receive(input)
//            }
//
//            demand = getDemand()
//
//            if demand == .none, !isCompleted {
//                isCompleted.toggle()
//                receive(completion: .finished)
//            }
        }
        
        override func receive(completion: NKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
            end()
        }
        
        override func cancel() {
            super.cancel()
            cancelBlock?()
            cancelBlock = nil
        }
    }
}
