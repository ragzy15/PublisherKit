//
//  Data Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import PublisherKit
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    
    /// Returns a publisher that wraps a URL session data task for a given URL.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a data task.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a data task for the URL.
    public func dataTaskPKPublisher(for url: URL, name: String = "") -> DataTaskPKPublisher {
        let request = URLRequest(url: url)
        return DataTaskPKPublisher(name: name, request: request, session: self)
    }
    
    /// Returns a publisher that wraps a URL session data task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a data task.
    /// - Parameter name: Name for the task. Used for logging purpose only. 
    /// - Returns: A publisher that wraps a data task for the URL request.
    public func dataTaskPKPublisher(for request: URLRequest, name: String = "") -> DataTaskPKPublisher {
        DataTaskPKPublisher(name: name, request: request, session: self)
    }
}

extension URLSession {
    
    public struct DataTaskPKPublisher: PublisherKit.Publisher {
        
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = Error
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public let name: String
        
        public init(name: String = "", request: URLRequest, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subscriber.receive(subscription: Inner(downstream: subscriber, parent: self))
        }
    }
}

extension URLSession.DataTaskPKPublisher {
    
    // MARK: DATA TASK SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionDataTask?
        
        private let lock = Lock()
        private var downstream: Downstream?
        private var demand: Subscribers.Demand = .none
        
        private var parent: URLSession.DataTaskPKPublisher?
        
        init(downstream: Downstream, parent: URLSession.DataTaskPKPublisher) {
            self.downstream = downstream
            self.parent = parent
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard let parent = parent, task == nil else { lock.unlock(); return }
            
            task = parent.session.dataTask(with: parent.request) { [weak self] in
                self?.handleResponse(data: $0, response: $1, error: $2)
            }
            
            self.demand += demand
            
            lock.unlock()
            
            Logger.default.logAPIRequest(request: parent.request, name: parent.name)
            
            task?.resume()
        }
        
        private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
            lock.lock()
            guard demand > .none, let downstream = downstream else { lock.unlock(); return }
            terminate()
            lock.unlock()
            
            if let error = error {
                downstream.receive(completion: .failure(error))
            } else if let response = response as? HTTPURLResponse, let data = data {
                _ = downstream.receive((data, response))
                downstream.receive(completion: .finished)
            } else {
                downstream.receive(completion: .failure(URLError(.unknown)))
            }
        }
        
        func cancel() {
            lock.lock()
            guard downstream != nil else { lock.unlock(); return }
            let task = self.task
            terminate()
            lock.unlock()
            
            task?.cancel()
        }
        
        private func terminate() {
            downstream = nil
            demand = .none
            parent = nil
            task = nil
        }
        
        var description: String {
            "DataTaskPublisher"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("task", task as Any),
                ("downstream", downstream as Any),
                ("parent", parent as Any),
                ("demand", demand)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
