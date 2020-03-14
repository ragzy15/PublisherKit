//
//  Data Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

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
    
    @available(*, deprecated, renamed: "nkDataTaskPublisher")
    public func nkTaskPublisher(for url: URL, name: String = "") -> DataTaskPKPublisher {
        dataTaskPKPublisher(for: url, name: name)
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
    
    @available(*, deprecated, renamed: "nkDataTaskPublisher")
    public func nkTaskPublisher(for request: URLRequest, name: String = "") -> DataTaskPKPublisher {
        dataTaskPKPublisher(for: request, name: name)
    }
}

extension URLSession {
    
    @available(*, deprecated, renamed: "DataTaskPKPublisher")
    public typealias NKDataTaskPublisher = DataTaskPKPublisher
    
    public struct DataTaskPKPublisher: PublisherKit.Publisher {
        
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = Error
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public var name: String
        
        public init(name: String = "", request: URLRequest, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = Inner(downstream: subscriber)
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.resume(with: request, in: session)
            
            Logger.default.logAPIRequest(request: request, name: name)
        }
    }
}

extension URLSession.DataTaskPKPublisher {
    
    // MARK: DATA TASK SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure>, URLSessionTaskPublisherDelegate where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionDataTask?
        
        func resume(with request: URLRequest, in session: URLSession) {
            getLock().lock()
            guard task == nil else { getLock().unlock(); return }
            
            let completion = handleCompletion(subscriber: self)
            task = session.dataTask(with: request, completionHandler: completion)
            
            getLock().unlock()
            
            task?.resume()
        }
        
        override func end(completion: () -> Void) {
            super.end(completion: completion)
            task = nil
        }
        
        override func cancel() {
            super.cancel()
            task?.cancel()
            task = nil
        }
        
        override var description: String {
            "Data Task Publisher"
        }
    }
}
