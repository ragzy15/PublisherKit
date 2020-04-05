//
//  Print.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers {
    
    /// A publisher that prints log messages for all publishing events, optionally prefixed with a given string.
    ///
    /// This publisher prints log messages when receiving the following events:
    /// * subscription
    /// * value
    /// * normal completion
    /// * failure
    /// * cancellation
    public struct Print<Upstream: Publisher>: Publisher {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Upstream.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: Upstream
        
        /// A string with which to prefix all log messages.
        public let prefix: String
        
        /// An output stream to receive the text representation of each item.
        public let stream: TextOutputStream?
        
        /// Creates a publisher that prints log messages for all publishing events.
        ///
        /// - Parameters:
        ///   - upstream: The publisher from which this publisher receives elements.
        ///   - prefix: A string with which to prefix all log messages.
        ///   - stream: An output stream to receive the text representation of each item.
        public init(upstream: Upstream, prefix: String, to stream: TextOutputStream? = nil) {
            self.upstream = upstream
            self.prefix = prefix
            self.stream = stream
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            upstream.subscribe(Inner(downstream: subscriber, prefix: prefix, to: stream))
        }
    }
}


extension Publishers.Print {
    
    // MARK: PRINT SINK
    private final class Inner<Downstream: Subscriber>: Subscriber, Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let prefix: String
        
        private struct OutputStream: TextOutputStream {
           var stream: TextOutputStream

            mutating func write(_ string: String) {
                stream.write(string)
            }
        }
        
        private var stream: OutputStream?
        
        private let lock = Lock()
        private var downstream: Downstream?
        private var status: SubscriptionStatus = .awaiting
        
        init(downstream: Downstream, prefix: String, to stream: TextOutputStream?) {
            self.prefix = prefix.isEmpty ? prefix : prefix + ": "
            self.stream = stream.map { OutputStream(stream: $0) }
            self.downstream = downstream
        }
        
        func receive(subscription: Subscription) {
            lock.lock()
            guard status == .awaiting else { lock.unlock(); return }
            status = .subscribed(to: subscription)
            lock.unlock()
            
            print("receive subscription: (\(subscription))")
            downstream?.receive(subscription: self)
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard case .subscribed(let subscription) = status else {
                lock.unlock()
                return
            }
            lock.unlock()
            
            if let max = demand.max {
                print("request max: (\(max))")
            } else {
                print("request unlimited")
            }
            
            subscription.request(demand)
        }
        
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return .none }
            lock.unlock()
            
            print("receive value: (\(input))")
            return downstream?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard status.isSubscribed else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            switch completion {
            case .finished:
                print("receive finished")
            case .failure(let error):
                print("receive error: (\(error))")
            }
            
            downstream?.receive(completion: completion)
        }
        
        func cancel() {
            lock.lock()
            guard case .subscribed(let subscription) = status else { lock.unlock(); return }
            status = .terminated
            lock.unlock()
            
            print("receive cancel")
            subscription.cancel()
        }
        
        func print(_ text: String) {
            let text = "\(prefix)\(text)"
            
            if var stream = stream {
                Swift.print(text, to: &stream)
            } else {
                Swift.print(text)
            }
        }
        
        var description: String {
            "Print"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
