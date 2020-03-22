//
//  Abstract Combine Latest.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 22/03/20.
//

final class AbstractCombineLatest<Downstream: Subscriber, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
    
    private var downstream: Downstream?
    
    private var buffers: [Any?]
    private var upstreamSubscriptions: [Subscription?]
    
    private let upstreamCount: Int
    private var finishedSubscriptions: Int = 0
    
    private let lock = Lock()
    private let downstreamLock = RecursiveLock()
    
    private var demand: Subscribers.Demand = .none
    
    private var isTerminated = false
    private var isActive = false
    
    init(downstream: Downstream, upstreamCount: Int) {
        self.downstream = downstream
        self.upstreamCount = upstreamCount
        self.buffers = Array(repeating: nil, count: upstreamCount)
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
    }
    
    fileprivate final func receive(subscription: Subscription, index: Int) {
        lock.lock()
        guard !isTerminated && upstreamSubscriptions[index] == nil else {
            lock.unlock()
            subscription.cancel()
            return
        }
        upstreamSubscriptions[index] = subscription
        lock.unlock()
    }
    
    fileprivate final func receive(_ input: Any, index: Int) -> Subscribers.Demand {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return .none }
        
        buffers[index] = input
        
        guard !isActive, demand > 0, buffers.allSatisfy ({ $0 != nil }) else { lock.unlock(); return .none }
        
        demand -= 1
        isActive = true
        lock.unlock()
        
        downstreamLock.lock()
        let output = buffers.compactMap { $0 }.tuple as! Output
        let additionalDemand = downstream?.receive(output) ?? .none
        downstreamLock.unlock()
        
        lock.lock()
        isActive = false
        demand += additionalDemand
        lock.unlock()
        
        return demand
    }
    
    fileprivate final func receive(completion: Subscribers.Completion<Failure>, index: Int) {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        
        switch completion {
        case .finished:
            finishedSubscriptions += 1
            upstreamSubscriptions[index] = nil
            
            guard finishedSubscriptions == upstreamCount else { lock.unlock(); return }
            
            isTerminated = true
            buffers = Array(repeating: nil, count: upstreamCount)
            lock.unlock()
            
            downstreamLock.lock()
            downstream?.receive(completion: .finished)
            downstreamLock.unlock()
            
        case .failure(let error):
            isTerminated = true
            
            let upstreamSubscriptions = self.upstreamSubscriptions
            self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
            
            buffers = Array(repeating: nil, count: upstreamCount)
            lock.unlock()
            
            for (i, subscription) in upstreamSubscriptions.enumerated() where i != index {
                subscription?.cancel()
            }
            
            downstreamLock.lock()
            downstream?.receive(completion: .failure(error))
            downstreamLock.unlock()
        }
    }
}

extension AbstractCombineLatest: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        self.demand += demand
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.request(demand)
        }
    }
    
    func cancel() {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        isTerminated = true
        
        let upstreamSubscriptions = self.upstreamSubscriptions
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        
        buffers = Array(repeating: nil, count: upstreamCount)
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.cancel()
        }
    }
    
    var description: String {
        "CombineLatest"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        lock.lock()
        defer { lock.unlock() }
        
        let children: [Mirror.Child] = [
            ("downstream", downstream as Any),
            ("upstreamSubscriptions", upstreamSubscriptions),
            ("demand", demand),
            ("buffers", buffers)
        ]
        
        return Mirror(self, children: children)
    }
}

extension AbstractCombineLatest {
    
    struct Side<Input>: Subscriber, CustomStringConvertible {
        
        private let index: Int
        private let abstractCombineLatest: AbstractCombineLatest
        
        let combineIdentifier = CombineIdentifier()
        
        init(index: Int, abstractCombineLatest: AbstractCombineLatest) {
            self.index = index
            self.abstractCombineLatest = abstractCombineLatest
        }
        
        func receive(subscription: Subscription) {
            abstractCombineLatest.receive(subscription: subscription, index: index)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            abstractCombineLatest.receive(input, index: index)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            abstractCombineLatest.receive(completion: completion, index: index)
        }
        
        var description: String {
            "CombineLatest"
        }
    }
}
