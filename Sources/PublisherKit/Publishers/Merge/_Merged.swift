//
//  _Merged.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 22/03/20.
//

extension Publishers {
    
    final class _Merged<Downstream: Subscriber> {
        
        typealias Input = Downstream.Input
        
        typealias Failure = Downstream.Failure
        
        private var downstream: Downstream?
        
        private var upstreamSubscriptions: [Subscription?]
        
        private let upstreamCount: Int
        private var finishedSubscriptions: Int = 0
        
        private let lock = Lock()
        private let downstreamLock = RecursiveLock()
        
        private var demand: Subscribers.Demand = .max(1)
        
        private var isCancelled = false
        private var isFinished = false
        private var isActive = false
        
        init(downstream: Downstream, upstreamCount: Int) {
            self.downstream = downstream
            self.upstreamCount = upstreamCount
            self.upstreamSubscriptions = Array(repeating: nil, count: upstreamCount)
        }
        
        fileprivate final func receive(subscription: Subscription, _ index: Int) {
            lock.lock()
            guard !isCancelled && upstreamSubscriptions[index] == nil else {
                lock.unlock()
                subscription.cancel()
                return
            }
            
            upstreamSubscriptions[index] = subscription
            lock.unlock()
            subscription.request(demand)
        }
        
        fileprivate final func receive(_ input: Input, _ index: Int) -> Subscribers.Demand {
            lock.lock()
            if isCancelled || isFinished { lock.unlock(); return .none }
            
            guard !isActive, demand > 0 else { lock.unlock(); return .none }
            
            demand -= 1
            isActive = true
            lock.unlock()
            
            downstreamLock.lock()
            let additionalDemand = downstream?.receive(input) ?? .none
            downstreamLock.unlock()
            
            lock.lock()
            isActive = false
            demand += additionalDemand
            lock.unlock()
            
            return demand
        }
        
        fileprivate final func receive(completion: Subscribers.Completion<Failure>, _ index: Int) {
            guard !isFinished else { lock.unlock(); return }
            
            switch completion {
            case .finished:
                lock.lock()
                
                finishedSubscriptions += 1
                upstreamSubscriptions[index] = nil
                
                guard finishedSubscriptions == upstreamCount else { lock.unlock(); return }
                
                isFinished = true
                lock.unlock()
                
                downstreamLock.lock()
                downstream?.receive(completion: .finished)
                downstreamLock.unlock()
                
            case .failure(let error):
                lock.lock()
                isFinished = true
                
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
        
        struct Side: Subscriber, CustomStringConvertible {
            
            private let index: Int
            private let merged: _Merged
            
            let combineIdentifier = CombineIdentifier()
            
            init(index: Int, merged: _Merged) {
                self.index = index
                self.merged = merged
            }
            
            func receive(subscription: Subscription) {
                merged.receive(subscription: subscription, index)
            }
            
            func receive(_ input: Input) -> Subscribers.Demand {
                merged.receive(input, index)
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {
                merged.receive(completion: completion, index)
            }
            
            var description: String {
                "Merge"
            }
        }
    }
}

extension Publishers._Merged: Subscription, CustomStringConvertible, CustomReflectable {
    
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
        lock.unlock()
        
        for subscription in upstreamSubscriptions {
            subscription?.cancel()
        }
    }
    
    var description: String {
        "Merge"
    }
    
    var customMirror: Mirror {
        Mirror(self, children: [])
    }
}