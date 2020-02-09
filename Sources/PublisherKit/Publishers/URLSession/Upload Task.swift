//
//  Upload Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter data: The body data for the request.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func uploadTaskPKPublisher(for request: URLRequest, from data: Data?, name: String = "") -> UploadTaskPKPublisher {
        UploadTaskPKPublisher(name: name, request: request, from: data, session: self)
    }
    
    @available(*, deprecated, renamed: "uploadTaskPKPublisher")
    public func uploadTaskPublisher(for request: URLRequest, from data: Data?, name: String = "") -> UploadTaskPKPublisher {
        uploadTaskPKPublisher(for: request, from: data, name: name)
    }
    
    /// Returns a publisher that wraps a URL session upload task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a upload task.
    /// - Parameter file: The URL of the file to upload.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a upload task for the URL request.
    public func uploadTaskPKPublisher(for request: URLRequest, from file: URL, name: String = "") -> UploadTaskPKPublisher {
        UploadTaskPKPublisher(name: name, request: request, from: file, session: self)
    }
    
    @available(*, deprecated, renamed: "uploadTaskPKPublisher")
    public func uploadTaskPublisher(for request: URLRequest, from file: URL, name: String = "") -> UploadTaskPKPublisher {
        uploadTaskPKPublisher(for: request, from: file, name: name)
    }
}

extension URLSession {
    
    public struct UploadTaskPKPublisher: PublisherKit.Publisher, URLSessionTaskPublisherDelegate {
        
        public typealias Output = (data: Data, response: HTTPURLResponse)
        
        public typealias Failure = Error
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let uploadTaskSubscriber = InternalSink(downstream: subscriber)
            
            subscriber.receive(subscription: uploadTaskSubscriber)
            uploadTaskSubscriber.request(.max(1))
            
            if let url = fileUrl {
                uploadTaskSubscriber.resume(with: request, fromFile: url, in: session)
            } else {
                uploadTaskSubscriber.resume(with: request, from: data, in: session)
            }
            
            Logger.default.logAPIRequest(request: request, name: name)
        }
    }
}

extension URLSession.UploadTaskPKPublisher {
    
    /// Validates that the response has a status code acceptable in the specified range, and that the response has a content type in the specified sequence.
    /// - Parameters:
    ///   - acceptableStatusCodes: The range of acceptable status codes. Default range of 200...299.
    ///   - acceptableContentTypes: The acceptable content types, which may specify wildcard types and/or subtypes. If provided `nil`, content type is not validated. Providing an empty Array uses default behaviour. By default the content type matches any specified in the **Accept** HTTP header field.
    public func validate(acceptableStatusCodes codes: [Int] = Array(200 ..< 300), acceptableContentTypes: [String]? = []) -> Publishers.Validate<Self> {
        Publishers.Validate(upstream: self, acceptableStatusCodes: codes, acceptableContentTypes: acceptableContentTypes)
    }
}

extension URLSession.UploadTaskPKPublisher {
    
    // MARK: UPLOAD TASK SINK
    private final class InternalSink<Downstream: Subscriber>: Subscribers.SubscriptionSink<Downstream, Output, Failure>, URLSessionTaskPublisherDelegate where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionUploadTask?
        
        override func receive(input: Output) {
            guard !isCancelled else { return }
            _ = downstream?.receive(input)
        }
        
        override func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            downstream?.receive(completion: completion)
        }
        
        func resume(with request: URLRequest, from data: Data?, in session: URLSession) {
            task = session.uploadTask(with: request, from: data, completionHandler: getCompletion())
            task?.resume()
        }
        
        func resume(with request: URLRequest, fromFile fileUrl: URL, in session: URLSession) {
            task = session.uploadTask(with: request, fromFile: fileUrl, completionHandler: getCompletion())
            task?.resume()
        }
        
        @inline(__always)
        private func getCompletion() -> (Data?, URLResponse?, Error?) -> Void {
            handleCompletion(queue: URLSession.UploadTaskPKPublisher.queue, subscriber: self)
        }
        
        override func end() {
            task = nil
            super.end()
        }
        
        override func cancel() {
            task?.cancel()
            super.cancel()
        }
    }
}
