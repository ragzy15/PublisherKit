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
    public func nkDataTaskPublisher(for url: URL, apiName: String = "") -> NKDataTaskPublisher {
        let request = URLRequest(url: url)
        return NKDataTaskPublisher(name: apiName, request: request, session: self)
    }
    
    @available(*, deprecated, renamed: "nkDataTaskPublisher")
    public func nkTaskPublisher(for url: URL, apiName: String = "") -> NKDataTaskPublisher {
        nkDataTaskPublisher(for: url, apiName: apiName)
    }
    
    /// Returns a publisher that wraps a URL session data task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a data task.
    /// - Returns: A publisher that wraps a data task for the URL request.
    public func nkDataTaskPublisher(for request: URLRequest, apiName: String = "") -> NKDataTaskPublisher {
        NKDataTaskPublisher(name: apiName, request: request, session: self)
    }
    
    @available(*, deprecated, renamed: "nkDataTaskPublisher")
    public func nkTaskPublisher(for request: URLRequest, apiName: String = "") -> NKDataTaskPublisher {
        nkDataTaskPublisher(for: request, apiName: apiName)
    }
}

extension URLSession {
    
    public struct NKDataTaskPublisher: NKPublisher {
         
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = NSError
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public var apiName: String = ""
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.task-thread", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        
        public init(request: URLRequest, session: URLSession) {
            self.request = request
            self.session = session
        }
        
        public init(name: String, request: URLRequest, session: URLSession) {
            apiName = name
            self.request = request
            self.session = session
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = NKSubscribers.DataTaskSink(downstream: subscriber)
            
            dataTaskSubscriber.task = session.dataTask(with: request) { (data, response, error) in
                
                guard !dataTaskSubscriber.isCancelled else { return }
                
                if let error = error as NSError? {
                    NKDataTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(completion: .failure(error))
                    }
                    
                } else if let response = response as? HTTPURLResponse, let data = data {
                    NKDataTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(input: (data, response))
                        dataTaskSubscriber.receive(completion: .finished)
                    }
                }
            }
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.task?.resume()
            
            #if DEBUG
            Logger.default.logAPIRequest(request: request, apiName: apiName)
            #endif
        }
    }
}

extension URLSession.NKDataTaskPublisher {
    
    func validate(shouldCheckForErrorModel flag: Bool, acceptableStatusCodes codes: [Int]) -> NKPublishers.Validate {
        NKPublishers.Validate(upstream: self, shouldCheckForErrorModel: flag, acceptableStatusCodes: codes)
    }
}
