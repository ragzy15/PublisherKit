//
//  Operator Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

typealias UpstreamOperatorSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure>

extension PKSubscribers {
    
    final class OperatorSink<Downstream: PKSubscriber, Input, Failure: Error>: InternalSink<Downstream, Input, Failure> {
        
        final let receiveValue: ((Input) -> Void)
        
        final let receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)
        
        init(downstream: Downstream,
             receiveCompletion: @escaping (PKSubscribers.Completion<Failure>) -> Void,
             receiveValue: @escaping ((Input) -> Void)) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion)
        }
    }
}

// MARK: SAME FAILURE
typealias SameUpstreamFailureOperatorSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.SameFailureOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Failure == Upstream.Failure

extension PKSubscribers {
    
    final class SameFailureOperatorSink<Downstream: PKSubscriber, Input, Failure>: InternalSink<Downstream, Input, Failure> where Downstream.Failure == Failure {
        
        final let receiveValue: ((Input) -> Void)
        
        init(downstream: Downstream, receiveValue: @escaping ((Input) -> Void)) {
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}

// MARK: SAME OUTPUT
typealias SameUpstreamOutputOperatorSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.SameOutputOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output

extension PKSubscribers {
    
    final class SameOutputOperatorSink<Downstream: PKSubscriber, Input, Failure: Error>: InternalSink<Downstream, Input, Failure> where Downstream.Input == Input {
        
        final let receiveCompletion: ((PKSubscribers.Completion<Failure>) -> Void)
        
        init(downstream: Downstream, receiveCompletion: @escaping ((PKSubscribers.Completion<Failure>) -> Void)) {
            self.receiveCompletion = receiveCompletion
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion)
        }
    }
}

// MARK: SAME OPERATOR TYPE
typealias SameUpstreamOperatorSink<Downstream: PKSubscriber, Upstream: PKPublisher> = PKSubscribers.SameOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure

extension PKSubscribers {
    
    class SameOperatorSink<Downstream: PKSubscriber, Input, Failure>: InternalSink<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func receive(_ input: Input) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        func receive(input: Input) {
            _ = receive(input)
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
