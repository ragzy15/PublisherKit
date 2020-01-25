//
//  Validate.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public extension PKPublishers {
    
    struct Validate: PKPublisher {
        
        public typealias Output = URLSession.DataTaskPKPublisher.Output
        
        public typealias Failure = URLSession.DataTaskPKPublisher.Failure
        
        /// The publisher from which this publisher receives elements.
        public let upstream: URLSession.DataTaskPKPublisher
        
        /// Check for any business error model on failure.
        public let shouldCheckForErrorModel: Bool
        
        /// Acceptable HTTP Status codes for the network call.
        public let acceptableStatusCodes: [Int]
        
        public init(upstream: URLSession.DataTaskPKPublisher, shouldCheckForErrorModel: Bool, acceptableStatusCodes: [Int]) {
            self.upstream = upstream
            self.shouldCheckForErrorModel = shouldCheckForErrorModel
            
            self.acceptableStatusCodes = acceptableStatusCodes
        }
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let upstreamSubscriber = SameUpstreamFailureOperatorSink<S, Self>(downstream: subscriber) { (value) in
                let result = self.doValidation(output: value)
                
                switch result {
                case .success(let newOutput):
                    _ = subscriber.receive(newOutput)
                    
                case .failure(let error):
                    subscriber.receive(completion: .failure(error))
                }
            }
            
            subscriber.receive(subscription: upstreamSubscriber)
            upstreamSubscriber.request(.max(1))
            upstream.subscribe(upstreamSubscriber)
        }
    }
}


extension PKPublishers.Validate {
    
    private func doValidation(output: Output) -> Result<Output, Failure> {
        let url = upstream.request.url!
        let (data, response) = output
        
        if acceptableStatusCodes.contains(response.statusCode) {
            
            guard !data.isEmpty else {
                return .failure(.zeroByteResource(for: url))
            }
            
            var acceptableContentTypes: [String] {
                if let accept = upstream.request.value(forHTTPHeaderField: "Accept") {
                    return accept.components(separatedBy: ",")
                }
                
                return ["*/*"]
            }
            
            guard let responseContentType = response.mimeType, let responseMIMEType = MIMEType(responseContentType) else {
                for contentType in acceptableContentTypes {
                    if let mimeType = MIMEType(contentType), mimeType.isWildcard {
                        return .success((data, response))
                    }
                }
                return .failure(.cannotDecodeContentData(for: url))
            }
            
            for contentType in acceptableContentTypes {
                if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                    return .success((data, response))
                }
            }
            
            return .failure(.cannotDecodeContentData(for: url))
            
        } else {
            // On Failure it checks if it a business error.
            
            if shouldCheckForErrorModel, !data.isEmpty {
                
                let model = try? JSONDecoder().decode(ErrorModel.self, from: data)
                if let errorModel = model {
                    let error = NSError(domain: NSError.publisherKitErrorDomain, code: errorModel.code ?? response.statusCode, userInfo: [NSLocalizedDescriptionKey: model?.message ?? "null", NSURLErrorFailingURLErrorKey: url])
                    return .failure(error)
                }
            }
            
            // else throw http or url error
            if let httpError = HTTPStatusCode(rawValue: response.statusCode) {
                return .failure(httpError as NSError)
            } else {
                return .failure(.badServerResponse(for: url))
            }
        }
    }
}


private extension PKPublishers.Validate {
    
    /// ACCEPTABLE CONTENT TYPE CHECK
    struct MIMEType {
        let type: String
        let subtype: String
        
        var isWildcard: Bool { return type == "*" && subtype == "*" }
        
        init?(_ string: String) {
            let components: [String] = {
                let stripped = string.trimmingCharacters(in: .whitespacesAndNewlines)
                let split = stripped[..<(stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)]
                return split.components(separatedBy: "/")
            }()
            
            if let type = components.first, let subtype = components.last {
                self.type = type
                self.subtype = subtype
            } else {
                return nil
            }
        }
        
        func matches(_ mime: MIMEType) -> Bool {
            switch (type, subtype) {
            case (mime.type, mime.subtype), (mime.type, "*"), ("*", mime.subtype), ("*", "*"):
                return true
            default:
                return false
            }
        }
    }
}
