//
//  Upload Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension URLSession {
    
    /// Returns a publisher that wraps a URL session upload task for a given URL.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a upload task.
    /// - Parameter data: The body data for the request.
    /// - Returns: A publisher that wraps a upload task for the URL.
    public func nkUploadTaskPublisher(for url: URL, from data: Data?, apiName: String = "") -> NKUploadTaskPublisher {
        let request = URLRequest(url: url)
        return NKUploadTaskPublisher(name: apiName, request: request, session: self, from: data)
    }
    
    /// Returns a publisher that wraps a URL session upload task for a given URL.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a upload task.
    /// - Parameter file: The URL of the file to upload.
    /// - Returns: A publisher that wraps a upload task for the URL.
    public func nkUploadTaskPublisher(for url: URL, from file: URL, apiName: String = "") -> NKUploadTaskPublisher {
        let request = URLRequest(url: url)
        return NKUploadTaskPublisher(name: apiName, request: request, session: self, from: file)
    }
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter data: The body data for the request.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func nkUploadTaskPublisher(for request: URLRequest, from data: Data?, apiName: String = "") -> NKUploadTaskPublisher {
        NKUploadTaskPublisher(name: apiName, request: request, session: self, from: data)
    }
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter file: The URL of the file to upload.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func nkUploadTaskPublisher(for request: URLRequest, from file: URL, apiName: String = "") -> NKUploadTaskPublisher {
        NKUploadTaskPublisher(name: apiName, request: request, session: self, from: file)
    }
}

extension URLSession {
    
    public struct NKUploadTaskPublisher: NKPublisher {
         
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = NSError
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public let data: Data?
        
        public var apiName: String = ""
        
        private let url: URL?
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.task-thread", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        
        public init(name: String = "", request: URLRequest, session: URLSession, from data: Data?) {
            apiName = name
            self.request = request
            self.session = session
            self.data = data
            url = nil
        }
        
        public init(name: String = "", request: URLRequest, session: URLSession, from file: URL) {
            apiName = name
            self.request = request
            self.session = session
            data = nil
            url = file
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = NKSubscribers.DataTaskSink(downstream: subscriber)
            
            let block: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
                
                guard !dataTaskSubscriber.isCancelled else { return }
                
                if let error = error as NSError? {
                    NKUploadTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(completion: .failure(error))
                    }
                    
                } else if let response = response as? HTTPURLResponse, let data = data {
                    NKUploadTaskPublisher.queue.async {
                        dataTaskSubscriber.receive(input: (data, response))
                        dataTaskSubscriber.receive(completion: .finished)
                    }
                }
            }
            
            if let url = url {
                dataTaskSubscriber.task = session.uploadTask(with: request, fromFile: url, completionHandler: block)
            } else {
                dataTaskSubscriber.task = session.uploadTask(with: request, from: data, completionHandler: block)
            }
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.task?.resume()
            
            #if DEBUG
            Logger.default.logAPIRequest(request: request, apiName: apiName)
            #endif
        }
    }
}
