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

public enum AcceptableContentTypes {
    case acceptOrWildcard
    case custom(contentTypes: [String])
}

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
        /// By default the content type matches any specified in the **Accept** HTTP header field.
        public let acceptableContentTypes: AcceptableContentTypes?
        
        /// Validates that the response has a status code acceptable in the specified range, and that the response has a content type in the specified sequence.
        /// - Parameters:
        ///   - upstream: A URLSession task publisher.
        ///   - acceptableStatusCodes: The range of acceptable status codes.
        ///   - acceptableContentTypes: The acceptable content types, which may specify wildcard types and/or subtypes. If provided `nil`, content type is not validated.
        public init(upstream: Upstream, acceptableStatusCodes: [Int], acceptableContentTypes: AcceptableContentTypes?) {
            self.upstream = upstream
            self.acceptableStatusCodes = acceptableStatusCodes
            self.acceptableContentTypes = acceptableContentTypes
        }
        
        @available(*, unavailable, message: "Please use initializer with acceptableContentTypes as `AcceptableContentTypes` enum.")
        public init(upstream: Upstream, acceptableStatusCodes: [Int], acceptableContentTypes: [String]?) {
            self.upstream = upstream
            self.acceptableStatusCodes = acceptableStatusCodes
            
            if let contentTypes = acceptableContentTypes {
                self.acceptableContentTypes = .custom(contentTypes: contentTypes)
            } else {
                self.acceptableContentTypes = .acceptOrWildcard
            }
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let validationSubscriber = Inner(downstream: subscriber,
                                             acceptableStatusCodes: acceptableStatusCodes,
                                             acceptableContentTypes: acceptableContentTypes)
            upstream.subscribe(validationSubscriber)
        }
    }
}

extension Publishers.Validate {
    
    // MARK: VALIDATE SINK
    fileprivate final class Inner<Downstream: Subscriber>: InternalSubscriber<Downstream, Upstream> where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let acceptableStatusCodes: [Int]
        private let acceptableContentTypes: AcceptableContentTypes?
        
        init(downstream: Downstream, acceptableStatusCodes: [Int], acceptableContentTypes: AcceptableContentTypes?) {
            self.acceptableStatusCodes = acceptableStatusCodes
            self.acceptableContentTypes = acceptableContentTypes
            super.init(downstream: downstream)
            requiredDemand = .max(1)
        }
        
        override func operate(on input: Upstream.Output) -> Result<Downstream.Input, Downstream.Failure>? {
            return validate(input: input)
        }
        
        override func onCompletion(_ completion: Subscribers.Completion<Upstream.Failure>) {
            downstream?.receive(completion: completion.mapError { $0 as Failure })
        }
    }
}

private extension Publishers.Validate.Inner {
    
    func validate(input: Input) -> Result<Downstream.Input, Downstream.Failure> {
        
        let (data, response) = input
        
        guard acceptableStatusCodes.contains(response.statusCode) else {
            
            let error = HTTPStatusCode(rawValue: response.statusCode) ?? URLError.badServerResponse()
            return .failure(error)
        }
        
        guard !data.isEmpty else {
            return .success((data, response))
        }
        
        guard let acceptableContentTypes = acceptableContentTypes else {
            return .success((data, response))
        }
        
        var contentTypes: [String]
        
        switch acceptableContentTypes {
        case .acceptOrWildcard:
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                if let accept = response.value(forHTTPHeaderField: "Accept") {
                    contentTypes = accept.components(separatedBy: ",")
                } else {
                    contentTypes = ["*/*"]
                }
            } else {
                if let accept = response.allHeaderFields["Accept"] as? String {
                    contentTypes = accept.components(separatedBy: ",")
                } else {
                    contentTypes = ["*/*"]
                }
            }
            
        case .custom(let types): contentTypes = types
        }
        
        guard let responseContentType = response.mimeType, let responseMIMEType = MIMEType(responseContentType) else {
            for contentType in contentTypes {
                if let mimeType = MIMEType(contentType), mimeType.isWildcard {
                    return .success((data, response))
                }
            }
            return .failure(URLError.cannotDecodeContentData()) // did not receive response header for the response mime type.
        }
        
        for contentType in contentTypes {
            if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                return .success((data, response))
            }
        }
        
        return .failure(URLError.cannotDecodeContentData()) // content type cannot be validated.
    }
}


private extension Publishers.Validate.Inner {
    
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
