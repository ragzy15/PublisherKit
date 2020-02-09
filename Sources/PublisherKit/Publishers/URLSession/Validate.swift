//
//  Validate.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Publishers {
    
    public struct Validate<Upstream: Publisher>: Publisher where Upstream.Output == (data: Data, response: HTTPURLResponse) {
        
        public typealias Output = Upstream.Output
        
        public typealias Failure = Error
        
        public let upstream: Upstream
        
        /// Acceptable HTTP Status codes for the network call.
        public let acceptableStatusCodes: [Int]
        
        /// Acceptable Content Types codes for the network call.
        ///
        /// If provided `nil` then content type is not validated.
        ///
        /// If provided an empty Array, defaults to default behavious.
        ///
        /// By default the content type matches any specified in the **Accept** HTTP header field.
        public let acceptableContentTypes: [String]?
        
        /// Validates that the response has a status code acceptable in the specified range, and that the response has a content type in the specified sequence.
        /// - Parameters:
        ///   - upstream: A URLSession task publisher.
        ///   - acceptableStatusCodes: The range of acceptable status codes.
        ///   - acceptableContentTypes: The acceptable content types, which may specify wildcard types and/or subtypes. If provided `nil`, content type is not validated. Providing an empty Array uses default behaviour. By default the content type matches any specified in the **Accept** HTTP header field.
        public init(upstream: Upstream, acceptableStatusCodes: [Int], acceptableContentTypes: [String]?) {
            self.upstream = upstream
            self.acceptableStatusCodes = acceptableStatusCodes
            self.acceptableContentTypes = acceptableContentTypes
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let validationSubscriber = InternalSink(downstream: subscriber, acceptableStatusCodes: acceptableStatusCodes, acceptableContentTypes: acceptableContentTypes)
            
            validationSubscriber.request(.max(1))
            upstream.subscribe(validationSubscriber)
        }
    }
}

extension Publishers.Validate {
    
    // MARK: VALIDATE SINK
    fileprivate final class InternalSink<Downstream: Subscriber>: UpstreamOperatorSink<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let acceptableStatusCodes: [Int]
        private let acceptableContentTypes: [String]?
        
        init(downstream: Downstream, acceptableStatusCodes: [Int], acceptableContentTypes: [String]?) {
            self.acceptableStatusCodes = acceptableStatusCodes
            self.acceptableContentTypes = acceptableContentTypes
            super.init(downstream: downstream)
        }
        
        override func receive(_ input: (data: Data, response: HTTPURLResponse)) -> Subscribers.Demand {
            let result = validate(input: input)
            
            switch result {
            case .success(let newOutput):
                _ = downstream?.receive(newOutput)
                
            case .failure(let error):
                end()
                downstream?.receive(completion: .failure(error))
            }
            
            return demand
        }
    }
}

private extension Publishers.Validate.InternalSink {
    
    func validate(input: Input) -> Result<Downstream.Input, Downstream.Failure> {
        
        let (data, response) = input
        
        guard acceptableStatusCodes.contains(response.statusCode) else {
            
            // else throw http or url error
            if let httpError = HTTPStatusCode(rawValue: response.statusCode) {
                return .failure(httpError)
            } else {
                return .failure(URLError.badServerResponse())
            }
        }
        
        guard !data.isEmpty else {
            return .success((data, response))
        }
        
        var acceptableContentTypes: [String] {
            if let contentTypes = self.acceptableContentTypes {
                return contentTypes
            }
            
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                if let accept = response.value(forHTTPHeaderField: "Accept") {
                    return accept.components(separatedBy: ",")
                }
            } else {
                if let accept = response.allHeaderFields["Accept"] as? String {
                    return accept.components(separatedBy: ",")
                }
            }
            
            return ["*/*"]
        }
        
        guard let responseContentType = response.mimeType, let responseMIMEType = MIMEType(responseContentType) else {
            for contentType in acceptableContentTypes {
                if let mimeType = MIMEType(contentType), mimeType.isWildcard {
                    return .success((data, response))
                }
            }
            return .failure(URLError.cannotDecodeContentData()) // did not response header for response mime type
        }
        
        for contentType in acceptableContentTypes {
            if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                return .success((data, response))
            }
        }
        
        return .failure(URLError.cannotDecodeContentData())
    }
}


private extension Publishers.Validate.InternalSink {
    
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
