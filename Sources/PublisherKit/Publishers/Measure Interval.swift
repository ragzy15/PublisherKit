//
//  Measure Interval.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 27/03/20.
//

extension Publishers {
    
    /// A publisher that measures and emits the time interval between events received from an upstream publisher.
    public struct MeasureInterval<Upstream: Publisher, Context: Scheduler>: Publisher {
        
        public typealias Output = Context.PKSchedulerTimeType.Stride
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// The scheduler on which to deliver elements.
        public let scheduler: Context
        
        public init(upstream: Upstream, scheduler: Context) {
            self.upstream = upstream
            self.scheduler = scheduler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, parent: self))
        }
    }
}

extension Publishers.MeasureInterval {
    
    // MARK: Measure Interval SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        typealias Input = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        fileprivate typealias MeasureInterval = Publishers.MeasureInterval<Upstream, Context>
        
        private enum State {
            case awaiting(parent: MeasureInterval, downstream: Downstream)
            case subscribed(parent: MeasureInterval, downstream: Downstream, subscription: Subscription)
            case terminated
        }
        
        private var status: State
        
        private let lock = Lock()
        
        private var lastInterval: Context.PKSchedulerTimeType?
        
        init(downstream: Downstream, parent: MeasureInterval) {
            status = .awaiting(parent: parent, downstream: downstream)
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard case .awaiting(let parent, let downstream) = status else { lock.unlock(); return }
            status = .subscribed(parent: parent, downstream: downstream, subscription: subscription)
            lastInterval = parent.scheduler.now
            lock.unlock()
            
            downstream.receive(subscription: self)
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed(let parent, let downstream, let subscription) = status, let lastInterval = lastInterval else { lock.unlock(); return .none }
            let now = parent.scheduler.now
            self.lastInterval = now
            lock.unlock()
            
            let demand = downstream.receive(lastInterval.distance(to: now))
            
            if demand > .none {
                subscription.request(demand)
            }
            
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            lock.lock()
            guard case .subscribed(_, let downstream, _) = status else { lock.unlock(); return }
            status = .terminated
            lastInterval = nil
            lock.unlock()
            
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            lock.unlock()
            
            subscription.request(demand)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(_, _, let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lastInterval = nil
            lock.unlock()
            
            subscription.cancel()
        }
        
        var description: String {
            "MeasureInterval"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
