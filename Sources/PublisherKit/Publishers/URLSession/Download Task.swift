//
//  Download Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    
    /// Returns a publisher that wraps a URL session download task for a given URL.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL for which to create a download task.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a download task for the URL.
    public func downloadTaskPKPublisher(for url: URL, name: String = "") -> DownloadTaskPKPublisher {
        let request = URLRequest(url: url)
        return DownloadTaskPKPublisher(name: name, request: request, session: self)
    }
    
    /// Returns a publisher that wraps a URL session download task for a given URL request.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a download task.
    /// - Parameter name: Name for the task. Used for logging purpose only.
    /// - Returns: A publisher that wraps a download task for the URL request.
    public func downloadTaskPKPublisher(for request: URLRequest, name: String = "") -> DownloadTaskPKPublisher {
        DownloadTaskPKPublisher(name: name, request: request, session: self)
    }
    
    /// Returns a publisher that wraps a URL session download task for a given URL request.
    ///
    /// The publisher publishes file URL when the task completes, or terminates if the task fails with an error.
    /// - Parameter data: A data object that provides the data necessary to resume the download.
    /// - Parameter name: Name for the task. Used for logging purpose only. 
    /// - Returns: A publisher that wraps a download task for the URL request.
    public func downloadTaskPKPublisher(withResumeData data: Data, name: String = "") -> DownloadTaskPKPublisher {
        DownloadTaskPKPublisher(name: name, withResumeData: data, session: self)
    }
}

extension URLSession {
    
    public struct DownloadTaskPKPublisher: PublisherKit.Publisher {
        
        public typealias Output = (url: URL, response: HTTPURLResponse)
        
        public typealias Failure = Error
        
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
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let downloadTaskSubscriber = InternalSink(downstream: subscriber)
            
            subscriber.receive(subscription: downloadTaskSubscriber)
            
            if let request = request {
                downloadTaskSubscriber.resume(with: request, in: session)
                Logger.default.logAPIRequest(request: request, name: name)
            } else if let data = resumeData {
                downloadTaskSubscriber.resume(withResumeData: data, in: session)
            }
        }
    }
}

extension URLSession.DownloadTaskPKPublisher {
    
    // MARK: DOWNLOAD TASK SINK
    private final class InternalSink<Downstream: Subscriber>: Subscribers.InternalSink<Downstream, Output, Failure>, URLSessionTaskPublisherDelegate where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionDownloadTask?
        
        override init(downstream: Downstream) {
            super.init(downstream: downstream)
        }
        
        func resume(with request: URLRequest, in session: URLSession) {
            task = session.downloadTask(with: request, completionHandler: getCompletion())
            task?.resume()
        }
        
        func resume(withResumeData data: Data, in session: URLSession) {
            task = session.downloadTask(withResumeData: data, completionHandler: getCompletion())
            task?.resume()
        }
        
        @inline(__always)
        private func getCompletion() -> (URL?, URLResponse?, Error?) -> Void {
            
            let completion: (URL?, URLResponse?, Error?) -> Void = { [weak self] (url, response, error) in
                
                guard let `self` = self, !self.isCancelled else { return }
                
                if let error = error as NSError? {
                    URLSession.DownloadTaskPKPublisher.queue.async {
                        self.receive(completion: .failure(error))
                    }
                    
                } else if let response = response as? HTTPURLResponse, let url = url {
                    URLSession.DownloadTaskPKPublisher.queue.async {
                        _ = self.receive((url, response))
                        self.receive(completion: .finished)
                    }
                }
            }
            
            return completion
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
