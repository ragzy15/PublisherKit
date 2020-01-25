//
//  Data Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension URLSession {
    
    /// Returns a publisher that wraps a URL session data task for a given URL.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a data task.
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
    
    public struct DataTaskPKPublisher: PKPublisher, Handling {
         
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = NSError
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public var name: String
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.task-thread", qos: .utility, attributes: .concurrent)
        
        public init(name: String = "", request: URLRequest, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = DataTaskSink(downstream: subscriber)
            
            let completion = handle(queue: DataTaskPKPublisher.queue, subscriber: dataTaskSubscriber)
            
            dataTaskSubscriber.task = session.dataTask(with: request, completionHandler: completion)
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.task?.resume()
            
            #if DEBUG
            Logger.default.logAPIRequest(request: request, name: name)
            #endif
        }
    }
}

extension URLSession.DataTaskPKPublisher {
    
    func validate(shouldCheckForErrorModel flag: Bool, acceptableStatusCodes codes: [Int]) -> PKPublishers.Validate {
        PKPublishers.Validate(upstream: self, shouldCheckForErrorModel: flag, acceptableStatusCodes: codes)
    }
}
