//
//  Download Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension URLSession {
    
    /// Returns a publisher that wraps a URL session download task for a given URL.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a download task.
    /// - Returns: A publisher that wraps a download task for the URL.
    public func nkDownloadTaskPublisher(for url: URL, apiName: String = "") -> NKDownloadTaskPublisher {
        let request = URLRequest(url: url)
        return NKDownloadTaskPublisher(name: apiName, request: request, session: self)
    }
    
    /// Returns a publisher that wraps a URL session download task for a given URL request.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a download task.
    /// - Returns: A publisher that wraps a download task for the URL request.
    public func nkDownloadTaskPublisher(for request: URLRequest, apiName: String = "") -> NKDownloadTaskPublisher {
        NKDownloadTaskPublisher(name: apiName, request: request, session: self)
    }
}

extension URLSession {
    
    public struct NKDownloadTaskPublisher: NKPublisher {
         
        public typealias Output = (url: URL, response: HTTPURLResponse)
        
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
            
            dataTaskSubscriber.task = session.downloadTask(with: request) { (url, response, error) in
                
                guard !dataTaskSubscriber.isCancelled else { return }
                
                if let error = error as NSError? {
                    NKDownloadTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(completion: .failure(error))
                    }
                    
                } else if let response = response as? HTTPURLResponse, let url = url {
                    NKDownloadTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(input: (url, response))
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
