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
    public func dataTaskPKPublisher(for url: URL, name: String = "", downloadProgressHandler: ((Progress) -> Void)? = nil, uploadProgressHandler: ((Progress) -> Void)? = nil, taskProgressHandler: ((Progress) -> Void)? = nil) -> DataTaskPKPublisher {
        let request = URLRequest(url: url)
        return DataTaskPKPublisher(name: name, request: request, session: self, downloadProgressHandler: downloadProgressHandler, uploadProgressHandler: uploadProgressHandler, taskProgressHandler: taskProgressHandler)
    }
    
    /// Returns a publisher that wraps a URL session data task for a given URL request.
    ///
    /// The publisher publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter request: The URL request for which to create a data task.
    /// - Parameter name: Name for the task. Used for logging purpose only. 
    /// - Returns: A publisher that wraps a data task for the URL request.
    public func dataTaskPKPublisher(for request: URLRequest, name: String = "", downloadProgressHandler: ((Progress) -> Void)? = nil, uploadProgressHandler: ((Progress) -> Void)? = nil, taskProgressHandler: ((Progress) -> Void)? = nil) -> DataTaskPKPublisher {
        DataTaskPKPublisher(name: name, request: request, session: self, downloadProgressHandler: downloadProgressHandler, uploadProgressHandler: uploadProgressHandler, taskProgressHandler: taskProgressHandler)
    }
}

extension URLSession {
    
    public struct DataTaskPKPublisher: PublisherKit.Publisher {
        
        public typealias Output = (data: Data, response: URLResponse)
        
        public typealias Failure = Error
        
        public let request: URLRequest
        
        public let session: URLSession
        
        public let name: String
        
        public let downloadProgressHandler: ((Progress) -> Void)?
        public let uploadProgressHandler: ((Progress) -> Void)?
        public let taskProgressHandler: ((Progress) -> Void)?
        
        public init(name: String = "", request: URLRequest, session: URLSession, downloadProgressHandler: ((Progress) -> Void)?, uploadProgressHandler: ((Progress) -> Void)?, taskProgressHandler: ((Progress) -> Void)?) {
            self.name = name
            self.request = request
            self.session = session
            self.downloadProgressHandler = downloadProgressHandler
            self.uploadProgressHandler = uploadProgressHandler
            self.taskProgressHandler = taskProgressHandler
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subscriber.receive(subscription: Inner(downstream: subscriber, parent: self))
        }
    }
}

extension URLSession.DataTaskPKPublisher {
    
    // MARK: DATA TASK SINK
    private final class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var task: URLSessionDataTask?
        
        private let lock = Lock()
        private var downstream: Downstream?
        private var demand: Subscribers.Demand = .none
        
        private var parent: URLSession.DataTaskPKPublisher?
        
        private var uploadObserver: NSKeyValueObservation?
        private var downloadObserver: NSKeyValueObservation?
        
        init(downstream: Downstream, parent: URLSession.DataTaskPKPublisher) {
            self.downstream = downstream
            self.parent = parent
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard let parent = parent, task == nil else { lock.unlock(); return }
            
            let task = parent.session.dataTask(with: parent.request) { [weak self] in
                self?.handleResponse(data: $0, response: $1, error: $2)
            }
            
            self.task = task
            self.demand += demand
            
            lock.unlock()
            
            let uploadProgress = Progress(totalUnitCount: 0)
            uploadObserver = task.observe(\.countOfBytesSent) { (task, _) in
                let totalBytesExpected = task.countOfBytesExpectedToSend
                let totalBytesReceived = task.countOfBytesSent
                
                uploadProgress.totalUnitCount = totalBytesExpected
                uploadProgress.completedUnitCount = totalBytesReceived
            }
            
            let downloadProgress = Progress(totalUnitCount: 0)
            downloadObserver = task.observe(\.countOfBytesReceived) { (task, _) in
                let totalBytesExpected = task.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
                let totalBytesReceived = task.countOfBytesReceived
                
                downloadProgress.totalUnitCount = totalBytesExpected
                downloadProgress.completedUnitCount = totalBytesReceived
            }
            
            let taskProgress: Progress
            if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
                taskProgress = task.progress
            } else {
                let progress = Progress(totalUnitCount: 100)
                progress.addChild(uploadProgress, withPendingUnitCount: 50)
                progress.addChild(downloadProgress, withPendingUnitCount: 50)
                taskProgress = progress
            }
            
            DispatchQueue.main.async {
                parent.uploadProgressHandler?(uploadProgress)
                parent.downloadProgressHandler?(downloadProgress)
                parent.taskProgressHandler?(taskProgress)
            }
            
            Logger.default.logAPIRequest(request: parent.request, name: parent.name)
            
            task.resume()
        }
        
        private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
            lock.lock()
            guard demand > .none, let downstream = downstream else { lock.unlock(); return }
            terminate()
            lock.unlock()
            
            if let error = error {
                downstream.receive(completion: .failure(error))
            } else if let response = response, let data = data {
                _ = downstream.receive((data, response))
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
            uploadObserver?.invalidate()
            uploadObserver = nil
            downloadObserver?.invalidate()
            downloadObserver = nil
        }
        
        var description: String {
            "DataTaskPublisher"
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
