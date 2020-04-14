//
//  Download Task.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/01/20.
//

import PublisherKit
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
        
        public let name: String
        
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
            subscriber.receive(subscription: Inner(downstream: subscriber, parent: self))
        }
    }
}

extension URLSession.DownloadTaskPKPublisher {
    
    // MARK: DOWNLOAD TASK SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionDownloadTask?
        
        private let lock = Lock()
        private var downstream: Downstream?
        private var demand: Subscribers.Demand = .none
        
        private var parent: URLSession.DownloadTaskPKPublisher?
        
        init(downstream: Downstream, parent: URLSession.DownloadTaskPKPublisher) {
            self.downstream = downstream
            self.parent = parent
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard let parent = parent, task == nil else { lock.unlock(); return }
            
            if let request = parent.request {
                task = parent.session.downloadTask(with: request) { [weak self] in
                    self?.handleResponse(url: $0, response: $1, error: $2)
                }
                Logger.default.logAPIRequest(request: request, name: parent.name)
            } else if let data = parent.resumeData {
                task = parent.session.downloadTask(withResumeData: data) { [weak self] in
                    self?.handleResponse(url: $0, response: $1, error: $2)
                }
            }
            
            self.demand += demand
            
            lock.unlock()
            
            task?.resume()
        }
        
        private func handleResponse(url: URL?, response: URLResponse?, error: Error?) {
            lock.lock()
            guard demand > .none, let downstream = downstream else { lock.unlock(); return }
            terminate()
            lock.unlock()
            
            if let error = error {
                downstream.receive(completion: .failure(error))
            } else if let url = url, let response = response as? HTTPURLResponse {
                _ = downstream.receive((url, response))
                downstream.receive(completion: .finished)
            } else {
                downstream.receive(completion: .failure(URLError(.unknown)))
            }
        }
        
        func cancel() {
            lock.lock()
            guard downstream != nil else { lock.unlock(); return }
            let task = self.task
            terminate()
            lock.unlock()
            
            task?.cancel()
        }
        
        private func terminate() {
            downstream = nil
            demand = .none
            parent = nil
            task = nil
        }
        
        var description: String {
            "DownloadTaskPublisher"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("task", task as Any),
                ("downstream", downstream as Any),
                ("parent", parent as Any),
                ("demand", demand)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
