//
//  Abstract Zip.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 22/03/20.
//

final class AbstractZip<Downstream: Subscriber, Output, Failure> where Output == Downstream.Input, Failure == Downstream.Failure {
    
    private var downstream: Downstream?
    
    private var buffers: [Int: [Any]] = [:]
    private var upstreamSubscriptions: [Subscription?]
    
    private let upstreamCount: Int
    private var finishedSubscriptions: Int = 0
    
    private let lock = Lock()
    private let downstreamLock = RecursiveLock()
    
    private var demand: Subscribers.Demand = .none
    
    private var isCancelled = false
    private var isFinished = false
    private var isActive = false
    
    init(downstream: Downstream, upstreamCount: Int) {
        self.downstream = downstream
        self.upstreamCount = upstreamCount
        
        for i in 0 ..< upstreamCount {
            buffers[i] = []
        }
        
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
    }
    
    fileprivate final func receive(subscription: Subscription, index: Int) {
        lock.lock()
        guard !isCancelled && upstreamSubscriptions[index] == nil else {
            lock.unlock()
            subscription.cancel()
            return
        }
        upstreamSubscriptions[index] = subscription
        lock.unlock()
    }
    
    private func resolvePendingDemandAndUnlock() {
        
    }
    
    fileprivate final func receive(_ input: Any, index: Int) -> Subscribers.Demand {
        lock.lock()
        if isCancelled || isFinished { lock.unlock(); return .none }
        
        buffers[index]?.append(input)
        
        guard !isActive, demand > 0, buffers.allSatisfy ({ $0.value.first != nil }) else { lock.unlock(); return .none }
        
        demand -= 1
        isActive = true
        lock.unlock()
        
        downstreamLock.lock()
        
        
        let keys = buffers.keys.sorted()
        let values = keys.compactMap { buffers[$0]?.removeFirst() }
        let output = values.tuple as! Output
        
        let additionalDemand = downstream?.receive(output) ?? .none
        
        downstreamLock.unlock()
        
        lock.lock()
        isActive = false
        demand += additionalDemand
        lock.unlock()
        
        return demand
    }
    
    fileprivate final func receive(completion: Subscribers.Completion<Failure>, index: Int) {
        guard !isFinished else { lock.unlock(); return }
        
        switch completion {
        case .finished:
            lock.lock()
            
            finishedSubscriptions += 1
            upstreamSubscriptions[index] = nil
            
            guard finishedSubscriptions == upstreamCount else { lock.unlock(); return }
            
            isFinished = true
            for i in 0 ..< upstreamCount {
                buffers[i] = []
            }
            lock.unlock()
            
            downstreamLock.lock()
            downstream?.receive(completion: .finished)
            downstreamLock.unlock()
            
        case .failure(let error):
            lock.lock()
            isFinished = true
            
            let subscriptions = self.upstreamSubscriptions
            self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
            
            for i in 0 ..< upstreamCount {
                buffers[i] = []
            }
            lock.unlock()
            
            for (i, subscription) in subscriptions.enumerated() where i != index {
                subscription?.cancel()
            }
            
            downstreamLock.lock()
            downstream?.receive(completion: .failure(error))
            downstreamLock.unlock()
        }
    }
}

extension AbstractZip: Subscription, CustomStringConvertible, CustomReflectable {
    
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard !isCancelled && !isFinished else { lock.unlock(); return }
        self.demand += demand
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.request(demand)
        }
    }
    
    func cancel() {
        lock.lock()
        isCancelled = true
        let upstreamSubscriptions = self.upstreamSubscriptions
        self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        
        for i in 0 ..< upstreamCount {
            buffers[i] = []
        }
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.cancel()
        }
    }
    
    var description: String {
        "Zip"
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
