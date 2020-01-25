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
    public func downloadTaskPKPublisher(for url: URL, name: String = "") -> DownloadTaskPKPublisher {
        let request = URLRequest(url: url)
        return DownloadTaskPKPublisher(name: name, request: request, session: self)
    }
    
    /// Returns a publisher that wraps a URL session download task for a given URL request.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a download task.
    /// - Returns: A publisher that wraps a download task for the URL request.
    public func downloadTaskPKPublisher(for request: URLRequest, name: String = "") -> DownloadTaskPKPublisher {
        DownloadTaskPKPublisher(name: name, request: request, session: self)
    }
}

extension URLSession {
    
    public struct DownloadTaskPKPublisher: PKPublisher {
         
        public typealias Output = (url: URL, response: HTTPURLResponse)
        
        public typealias Failure = NSError
        
        public let request: URLRequest?
        
        public let resumeData: Data?
        
        public let session: URLSession
        
        public var name: String
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.download-task-thread", qos: .utility, attributes: .concurrent)
        
        public init(name: String = "", request: URLRequest, session: URLSession) {
            self.name = name
            resumeData = nil
            self.request = request
            self.session = session
        }
        
        public init(name: String = "", withResumeData data: Data, session: URLSession) {
            self.name = name
            request = nil
            self.resumeData = data
            self.session = session
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = DataTaskSink(downstream: subscriber)
            
            let completion: (URL?, URLResponse?, Error?) -> Void = { (url, response, error) in
                
                guard !dataTaskSubscriber.isCancelled else { return }
                
                if let error = error as NSError? {
                    DownloadTaskPKPublisher.queue.async {
                        dataTaskSubscriber.receive(completion: .failure(error))
                    }
                    
                } else if let response = response as? HTTPURLResponse, let url = url {
                    DownloadTaskPKPublisher.queue.async {
                        dataTaskSubscriber.receive(input: (url, response))
                        dataTaskSubscriber.receive(completion: .finished)
                    }
                }
            }
            
            if let request = request {
                dataTaskSubscriber.task = session.downloadTask(with: request, completionHandler: completion)
            } else if let data = resumeData {
                dataTaskSubscriber.task = session.downloadTask(withResumeData: data, completionHandler: completion)
            }
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.task?.resume()
            
            #if DEBUG
//            Logger.default.logAPIRequest(request: request, name: name)
            #endif
        }
    }
}
