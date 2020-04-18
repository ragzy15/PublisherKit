//
//  Abstract Zip.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 22/03/20.
//

final class AbstractZip<Downstream: Subscriber, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
    
    private var downstream: Downstream?
    
    private var buffers: [[Any]]
    private var upstreamSubscriptions: [Subscription?]
    
    private let upstreamCount: Int
    
    private let lock = Lock()
    private let downstreamLock = RecursiveLock()
    
    private var demand: Subscribers.Demand = .none
    
    private var isTerminated = false
    private var isActive = false
    private var isSubscriptionActive = false
    
    init(downstream: Downstream, upstreamCount: Int) {
        self.downstream = downstream
        self.upstreamCount = upstreamCount
        
        self.buffers = Array(repeating: [], count: upstreamCount)
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
        
        if upstreamSubscriptions.filter ({ $0 != nil }).count == upstreamCount {
            isSubscriptionActive = true
            lock.unlock()
            downstreamLock.lock()
            downstream?.receive(subscription: self)
            downstreamLock.unlock()
            lock.lock()
            isSubscriptionActive = false
        }
        
        resolvePendingDemandAndUnlock()
    }
    
    private func resolvePendingDemandAndUnlock() {
        guard demand > .none else {
            lock.unlock()
            return
        }
        
        upstreamSubscriptions.forEach { (subscription) in
            subscription?.request(demand)
        }
        
        lock.unlock()
    }
    
    fileprivate final func receive(_ input: Any, index: Int) -> Subscribers.Demand {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return .none }
        
        let anySubscriptionFinished = !upstreamSubscriptions.filter { $0 == nil }.isEmpty
        
        if anySubscriptionFinished {
            let bufferIsEmpty = buffers.filter { $0.isEmpty }.count == upstreamCount
            if bufferIsEmpty {
                lockedSendCompletion()
                return .none
            }
        }
        
        buffers[index].append(input)
        
        guard !isActive, demand > 0, buffers.allSatisfy ({ $0.first != nil }) else {
            lock.unlock()
            return .none
        }
        
        demand -= 1
        isActive = true
        
        var values: [Any] = []
        for (i, _) in buffers.enumerated() {
            values.append(buffers[i].removeFirst())
        }
        
        let output = values.tuple as! Output
        lock.unlock()
        
        downstreamLock.lock()
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
            upstreamSubscriptions[index] = nil
            
            let finishedSubscriptions = upstreamSubscriptions.filter { $0 == nil }.count == upstreamCount
            
            if buffers[index].isEmpty || finishedSubscriptions {
                lockedSendCompletion()
                return
            } else {
                lock.unlock()
            }
            
        case .failure(let error):
            isTerminated = true
            
            buffers = Array(repeating: [], count: upstreamCount)
            
            let subscriptions = self.upstreamSubscriptions
            self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
            lock.unlock()
            
            for (i, subscription) in subscriptions.enumerated() where i != index {
                subscription?.cancel()
            }
            
            downstreamLock.lock()
            downstream?.receive(completion: .failure(error))
            downstreamLock.unlock()
        }
    }
    
    private func lockedSendCompletion() {
        buffers = Array(repeating: [], count: upstreamCount)
        isTerminated = true
        lock.unlock()
        
        downstreamLock.lock()
        downstream?.receive(completion: .finished)
        downstreamLock.unlock()
    }
}

extension AbstractZip: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        self.demand += demand
        
        guard !isSubscriptionActive else {
            lock.unlock()
            return
        }
        
        upstreamSubscriptions.forEach { (subscription) in
            subscription?.request(demand)
        }
        
        lock.unlock()
    }
    
    func cancel() {
        lock.lock()
        guard !isTerminated else { lock.unlock(); return }
        isTerminated = true
        
        buffers = Array(repeating: [], count: upstreamCount)
        
        let upstreamSubscriptions = self.upstreamSubscriptions
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.cancel()
        }
    }
    
    var description: String {
        "Zip"
    }
    
    var playgroundDescription: Any {
        description
    }
    
    var customMirror: Mirror {
        Mirror(self, children: [])
    }
}

extension AbstractZip {
    
    struct Side<Input>: Subscriber, CustomStringConvertible {
        
        private let index: Int
        private let abstractZip: AbstractZip
        
        let combineIdentifier = CombineIdentifier()
        
        init(index: Int, abstractZip: AbstractZip) {
            self.index = index
            self.abstractZip = abstractZip
        }
        
        func receive(subscription: Subscription) {
            abstractZip.receive(subscription: subscription, index: index)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            abstractZip.receive(input, index: index)
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            abstractZip.receive(completion: completion, index: index)
        }
        
        var description: String {
            "Zip"
        }
    }
}
