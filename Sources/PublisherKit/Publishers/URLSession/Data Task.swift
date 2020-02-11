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
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.data-task-thread", qos: .utility, attributes: .concurrent)
        
        public init(name: String = "", request: URLRequest, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = Inner(downstream: subscriber)
            
            subscriber.receive(subscription: dataTaskSubscriber)
            dataTaskSubscriber.request(.max(1))
            
            dataTaskSubscriber.resume(with: request, in: session)
            
            Logger.default.logAPIRequest(request: request, name: name)
        }
    }
}

extension URLSession.DataTaskPKPublisher {
    
    /// Validates that the response has a status code acceptable in the specified range, and that the response has a content type in the specified sequence.
    /// - Parameters:
    ///   - acceptableStatusCodes: The range of acceptable status codes. Default range of 200...299.
    ///   - acceptableContentTypes: The acceptable content types, which may specify wildcard types and/or subtypes. If provided `nil`, content type is not validated. Providing an empty Array uses default behaviour. By default the content type matches any specified in the **Accept** HTTP header field.
    public func validate(acceptableStatusCodes: [Int] = Array(200 ..< 300), acceptableContentTypes: [String]? = []) -> Publishers.Validate<Self> {
        Publishers.Validate(upstream: self, acceptableStatusCodes: acceptableStatusCodes, acceptableContentTypes: acceptableContentTypes)
    }
}

extension URLSession.DataTaskPKPublisher {
    
    // MARK: DATA TASK SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure>, URLSessionTaskPublisherDelegate where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionTask?
        
        func resume(with request: URLRequest, in session: URLSession) {
            let completion = handleCompletion(queue: URLSession.DataTaskPKPublisher.queue, subscriber: self)
            task = session.dataTask(with: request, completionHandler: completion)
            task?.resume()
        }
        
        override func receive(input: Output) {
            guard !isTerminated else { return }
            _ = downstream?.receive(input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Failure>) {
            downstream?.receive(completion: completion)
        }
        
        override func end(completion: () -> Void) {
            task = nil
            super.end(completion: completion)
        }
        
        override func cancel() {
            task?.cancel()
            task = nil
            super.cancel()
        }
        
        override var description: String {
            "Data Task Publisher"
        }
    }
}
