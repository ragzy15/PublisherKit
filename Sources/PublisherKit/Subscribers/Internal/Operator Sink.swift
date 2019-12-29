//
//  Operator Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

typealias UpstreamOperatorSink<Downstream: NKSubscriber, Upstream: NKPublisher> = NKSubscribers.OperatorSink<Downstream, Upstream.Output, Upstream.Failure>

extension NKSubscribers {
    
    final class OperatorSink<Downstream: NKSubscriber, Input, Failure: Error>: InternalSink<Downstream, Input, Failure> {
        
        final let receiveValue: ((Input) -> Void)
        
        final let receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)
        
        init(downstream: Downstream,
             receiveCompletion: @escaping (NKSubscribers.Completion<Failure>) -> Void,
             receiveValue: @escaping ((Input) -> Void)) {
            
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input)
            return demand
        }
        
        override func receive(completion: NKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion)
        }
    }
}

// MARK: SAME FAILURE
typealias SameUpstreamFailureOperatorSink<Downstream: NKSubscriber, Upstream: NKPublisher> = NKSubscribers.SameFailureOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Failure == Upstream.Failure

extension NKSubscribers {
    
    final class SameFailureOperatorSink<Downstream: NKSubscriber, Input, Failure>: InternalSink<Downstream, Input, Failure> where Downstream.Failure == Failure {
        
        final let receiveValue: ((Input) -> Void)
        
        init(downstream: Downstream, receiveValue: @escaping ((Input) -> Void)) {
            self.receiveValue = receiveValue
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            receiveValue(input)
            return demand
        }
        
        override func receive(completion: NKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}

// MARK: SAME OUTPUT
typealias SameUpstreamOutputOperatorSink<Downstream: NKSubscriber, Upstream: NKPublisher> = NKSubscribers.SameOutputOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output

extension NKSubscribers {
    
    final class SameOutputOperatorSink<Downstream: NKSubscriber, Input, Failure: Error>: InternalSink<Downstream, Input, Failure> where Downstream.Input == Input {
        
        final let receiveCompletion: ((NKSubscribers.Completion<Failure>) -> Void)
        
        init(downstream: Downstream, receiveCompletion: @escaping ((NKSubscribers.Completion<Failure>) -> Void)) {
            self.receiveCompletion = receiveCompletion
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: NKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            receiveCompletion(completion)
        }
    }
}

// MARK: SAME OPERATOR TYPE
typealias SameUpstreamOperatorSink<Downstream: NKSubscriber, Upstream: NKPublisher> = NKSubscribers.SameOperatorSink<Downstream, Upstream.Output, Upstream.Failure> where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure

extension NKSubscribers {
    
    class SameOperatorSink<Downstream: NKSubscriber, Input, Failure>: InternalSink<Downstream, Input, Failure> where Downstream.Input == Input, Downstream.Failure == Failure {
        
        override func receive(_ input: Input) -> NKSubscribers.Demand {
            guard !isCancelled else { return .none }
            _ = downstream?.receive(input)
            return demand
        }
        
        override func receive(completion: NKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
    }
}
