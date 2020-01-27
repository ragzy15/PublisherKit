//
//  Upload Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//

import Foundation

extension URLSession {
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter data: The body data for the request.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func uploadTaskPublisher(for request: URLRequest, from data: Data?, name: String = "") -> UploadTaskPKPublisher {
        UploadTaskPKPublisher(name: name, request: request, from: data, session: self)
    }
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter file: The URL of the file to upload.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func uploadTaskPublisher(for request: URLRequest, from file: URL, name: String = "") -> UploadTaskPKPublisher {
        UploadTaskPKPublisher(name: name, request: request, from: file, session: self)
    }
}

extension URLSession {
    
    public struct UploadTaskPKPublisher: PKPublisher, URLSessionTaskPublisherDelegate {
         
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = NSError
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public let data: Data?
        
        private let fileUrl: URL?
        
        public var name: String
        
        private static let queue = DispatchQueue(label: "com.PublisherKit.upload-task-thread", qos: .utility, attributes: .concurrent)
        
        public init(name: String = "", request: URLRequest, from data: Data?, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
            self.data = data
            fileUrl = nil
        }
        
        public init(name: String = "", request: URLRequest, from file: URL, session: URLSession) {
            self.name = name
            self.request = request
            self.session = session
            data = nil
            fileUrl = file
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let dataTaskSubscriber = DataTaskSink(downstream: subscriber)
            
            let completion = handleCompletion(queue: UploadTaskPKPublisher.queue, subscriber: dataTaskSubscriber)
            
            if let url = fileUrl {
                dataTaskSubscriber.task = session.uploadTask(with: request, fromFile: url, completionHandler: completion)
            } else {
                dataTaskSubscriber.task = session.uploadTask(with: request, from: data, completionHandler: completion)
            }
            
            subscriber.receive(subscription: dataTaskSubscriber)
            
            dataTaskSubscriber.task?.resume()
            
            #if DEBUG
            Logger.default.logAPIRequest(request: request, name: name)
            #endif
        }
    }
}
