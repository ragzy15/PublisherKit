//
//  HTTPStatusCodes.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

/// HTTP Status Codes, obtained in `HTTPURLResponse`
public enum HTTPStatusCode: Int, LocalizedError, CaseIterable {
    
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102
    case earlyHints = 103
    
    
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case imUsed = 226
    
    
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    case permanentRedirect = 308
    
    
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    
    case imATeapot = 418
    case misdirectedRequest = 421
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case tooEarly = 425
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case isLoginTimeout = 440
    case nginxNoResponse = 444
    case isRetryWith = 449
    case blockedByWindowsParentalControls = 450
    case unavailableForLegalReasons = 451
    case nginxSSLCertificateError = 495
    case nginxSSLCertificateRequired = 496
    
    case nginxHTTPToHTTPS = 497
    case tokenExpired = 498
    case nginxClientClosedRequest = 499
    
    
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case bandwidthLimitExceeded = 509
    case notExtended = 510
    case networkAuthenticationRequired = 511
    case siteIsFrozen = 530
    case networkConnectTimeoutError = 599
    
    /// Retrieve the localized description for this error.
    public var localizedDescription: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }
    
    public var errorDescription: String? {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }
}

extension HTTPStatusCode {
    /// Informational - Request received, continuing process.
    public var isInformational: Bool {
        return isIn(range: 100...199)
    }
    /// Success - The action was successfully received, understood, and accepted.
    public var isSuccess: Bool {
        return isIn(range: 200...299)
    }
    /// Redirection - Further action must be taken in order to complete the request.
    public var isRedirection: Bool {
        return isIn(range: 300...399)
    }
    /// Client Error - The request contains bad syntax or cannot be fulfilled.
    public var isClientError: Bool {
        return isIn(range: 400...499)
    }
    /// Server Error - The server failed to fulfill an apparently valid request.
    public var isServerError: Bool {
        return isIn(range: 500...599)
    }
    
    /// - returns: `true` if the status code is in the provided range, false otherwise.
    private func isIn(range: ClosedRange<HTTPStatusCode.RawValue>) -> Bool {
        return range.contains(rawValue)
    }
}

extension HTTPStatusCode {
    
    public var name: String {
        switch self {
        case .continue:
        return "Continue"
        case .switchingProtocols:
            return "Switching Protocols"
        case .processing:
            return "Processing"
        case .earlyHints:
            return "Early Hints"
            
        case .ok:
            return "OK"
        case .created:
            return "Created"
        case .accepted:
            return "Accepted"
        case .nonAuthoritativeInformation:
            return "Non Authoritative Information"
        case .noContent:
            return "No Content"
        case .resetContent:
            return "Reset Content"
        case .partialContent:
            return "Partial Content"
        case .multiStatus:
            return "Multi-Status"
        case .alreadyReported:
            return "Already Reported"
        case .imUsed:
            return "IM Used"
            
        case .multipleChoices:
            return "Multiple Choices"
        case .movedPermanently:
            return "Moved Permanently"
        case .found:
            return "Found"
        case .seeOther:
            return "See Other"
        case .notModified:
            return "Not Modified"
        case .useProxy:
            return "Use Proxy"
        case .temporaryRedirect:
            return "Temporary Redirect"
        case .permanentRedirect:
            return "Permanent Redirect"
            
        case .badRequest:
            return "Bad Request"
        case .unauthorized:
            return "Unauthorized"
        case .paymentRequired:
            return "Payment Required"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .notAcceptable:
            return "Not Acceptable"
        case .proxyAuthenticationRequired:
            return "Proxy Authentication Required"
        case .requestTimeout:
            return "Request Timeout"
        case .conflict:
            return "Conflict"
        case .gone:
            return "Gone"
        case .lengthRequired:
            return "Length Required"
        case .preconditionFailed:
            return "Precondition Failed"
        case .payloadTooLarge:
            return "Payload Too Large"
        case .uriTooLong:
            return "URI Too Long"
        case .unsupportedMediaType:
            return "Unsupported Media Type"
        case .rangeNotSatisfiable:
            return "Range Not Satisfiable"
        case .expectationFailed:
            return "Expectation Failed"
        case .imATeapot:
            return "I'm a Teapot"
        case .misdirectedRequest:
            return "Misdirected Request"
        case .unprocessableEntity:
            return "Unprocessable Entity"
        case .locked:
            return "Locked"
        case .failedDependency:
            return "Failed Dependency"
        case .tooEarly:
            return "Too Early"
        case .upgradeRequired:
            return "Upgrade Required"
        case .preconditionRequired:
            return "Preconditioned Required"
        case .tooManyRequests:
            return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:
            return "Request Header Fields Too Large"
        case .isLoginTimeout:
            return "Login Timeout"
        case .nginxNoResponse:
            return "NGINX No Response"
        case .isRetryWith:
            return "Retry With"
        case .blockedByWindowsParentalControls:
            return "Blocked by Windows Parental Controls"
        case .unavailableForLegalReasons:
            return "Unavailable For Legal Reasons"
        case .nginxSSLCertificateError:
            return "NGINX SSL Certificate Error"
        case .nginxSSLCertificateRequired:
            return "NGINX SSL Certificate Required"
        case .nginxHTTPToHTTPS:
            return "NGINX HTTP Request Sent to HTTPS Port"
        case .tokenExpired:
            return "Invalid Token"
        case .nginxClientClosedRequest:
            return "NGINX Client Closed Request"
            
        case .internalServerError:
            return "Internal Server Error"
        case .notImplemented:
            return "Not Implemented"
        case .badGateway:
            return "Bad Gateway"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .gatewayTimeout:
            return "Gateway Timeout"
        case .httpVersionNotSupported:
            return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:
            return "Variant Also Negotiates"
        case .insufficientStorage:
            return "Insufficient Storage"
        case .loopDetected:
            return "Loop Detected"
        case .bandwidthLimitExceeded:
            return "Bandwidth Limit Exceeded"
        case .notExtended:
            return "Not Extended"
        case .networkAuthenticationRequired:
            return "Network Authentication Required"
        case .siteIsFrozen:
            return "Site is frozen"
        case .networkConnectTimeoutError:
            return "Network Connect Timout Error"
        }
    }
    
    public var codeLongDescription: String {
        switch self {
        case .continue:
            return "An interim response. Indicates the client that the initial part of the request has been received and has not yet been rejected by the server. The client SHOULD continue by sending the remainder of the request or, if the request has already been completed, ignore this response. The server MUST send a final response after the request has been completed."
        case .switchingProtocols:
            return "Sent in response to an Upgrade request header from the client, and indicates the protocol the server is switching to."
        case .processing:
            return "Indicates that the server has received and is processing the request, but no response is available yet."
        case .earlyHints:
            return "Primarily intended to be used with the Link header. It suggests the user agent start preloading the resources while the server prepares a final response."
        case .ok:
            return """
            It indicates that the REST API successfully carried out whatever action the client requested and that no more specific code in the 2xx series is appropriate.
            Unlike the 204 status code, a 200 response should include a response body. The information returned with the response is dependent on the method used in the request, for example:
            • GET an entity corresponding to the requested resource is sent in the response;
            • HEAD the entity-header fields corresponding to the requested resource are sent in the response without any message-body;
            • POST an entity describing or containing the result of the action;
            • TRACE an entity containing the request message as received by the end server.
            """
        case .created:
            return "A REST API responds with the 201 status code whenever a resource is created inside a collection. There may also be times when a new resource is created as a result of some controller action, in which case 201 would also be an appropriate response. The newly created resource can be referenced by the URI(s) returned in the entity of the response, with the most specific URI for the resource given by a Location header field.\nThe origin server MUST create the resource before returning the 201 status code. If the action cannot be carried out immediately, the server SHOULD respond with a 202 (Accepted) response instead."
        case .accepted:
            return "The request has been received but not yet acted upon. It is noncommittal, since there is no way in HTTP to later send an asynchronous response indicating the outcome of the request. It is intended for cases where another process or server handles the request, or for batch processing."
        case .nonAuthoritativeInformation:
            return "This response code means the returned meta-information is not exactly the same as is available from the origin server, but is collected from a local or a third-party copy. This is mostly used for mirrors or backups of another resource. Except for that specific case, the \"200 OK\" response is preferred to this status."
        case .noContent:
            return "There is no content to send for this request, but the headers may be useful. The user-agent may update its cached headers for this resource with the new ones."
        case .resetContent:
            return "Tells the user-agent to reset the document which sent this request."
        case .partialContent:
            return "This response code is used when the Range header is sent from the client to request only part of a resource."
        case .multiStatus:
            return "Conveys information about multiple resources, for situations where multiple status codes might be appropriate."
        case .alreadyReported:
            return "Used inside a <dav:propstat> response element to avoid repeatedly enumerating the internal members of multiple bindings to the same collection."
        case .imUsed:
            return "The server has fulfilled a GET request for the resource, and the response is a representation of the result of one or more instance-manipulations applied to the current instance."
        case .multipleChoices:
            return "The request has more than one possible response. The user-agent or user should choose one of them. (There is no standardized way of choosing one of the responses, but HTML links to the possibilities are recommended so the user can pick.)"
        case .movedPermanently:
            return "The 301 status code indicates that the REST API’s resource model has been significantly redesigned, and a new permanent URI has been assigned to the client’s requested resource. The REST API should specify the new URI in the response’s Location header, and all future requests should be directed to the given URI."
        case .found:
            return "This response code means that the URI of requested resource has been changed temporarily. Further changes in the URI might be made in the future. Therefore, this same URI should be used by the client in future requests."
        case .seeOther:
            return "The server sent this response to direct the client to get the requested resource at another URI with a GET request."
        case .notModified:
            return "This status code is similar to 204 (“No Content”) in that the response body must be empty. The critical distinction is that 204 is used when there is nothing to send in the body, whereas 304 is used when the resource has not been modified since the version specified by the request headers If-Modified-Since or If-None-Match.\nIn such a case, there is no need to retransmit the resource since the client still has a previously-downloaded copy.\nUsing this saves bandwidth and reprocessing on both the server and client, as only the header data must be sent and received in comparison to the entirety of the page being re-processed by the server, then sent again using more bandwidth of the server and client."
        case .useProxy:
            return "Defined in a previous version of the HTTP specification to indicate that a requested response must be accessed by a proxy. It has been deprecated due to security concerns regarding in-band configuration of a proxy."
        case .temporaryRedirect:
            return "The server sends this response to direct the client to get the requested resource at another URI with same method that was used in the prior request. This has the same semantics as the 302 Found HTTP response code, with the exception that the user agent must not change the HTTP method used: If a POST was used in the first request, a POST must be used in the second request."
        case .permanentRedirect:
            return "This means that the resource is now permanently located at another URI, specified by the Location: HTTP Response header. This has the same semantics as the 301 Moved Permanently HTTP response code, with the exception that the user agent must not change the HTTP method used: If a POST was used in the first request, a POST must be used in the second request."
        case .badRequest:
            return "The server could not understand the request due to invalid syntax."
        case .unauthorized:
            return "Although the HTTP standard specifies \"unauthorized\", semantically this response means \"unauthenticated\". That is, the client must authenticate itself to get the requested response."
        case .paymentRequired:
            return "This response code is reserved for future use. The initial aim for creating this code was using it for digital payment systems, however this status code is used very rarely and no standard convention exists."
        case .forbidden:
            return "The client does not have access rights to the content; that is, it is unauthorized, so the server is refusing to give the requested resource. Unlike 401, the client's identity is known to the server."
        case .notFound:
            return "The requested resource could not be found but may be available again in the future. Subsequent requests by the client are permissible."
        case .methodNotAllowed:
            return "The API responds with a 405 error to indicate that the client tried to use an HTTP method that the resource does not allow. For instance, a read-only resource could support only GET and HEAD, while a controller resource might allow GET and POST, but not PUT or DELETE.\nA 405 response must include the Allow header, which lists the HTTP methods that the resource supports. For example:\nAllow: GET, POST"
        case .notAcceptable:
            return "The 406 error response indicates that the API is not able to generate any of the client’s preferred media types, as indicated by the Accept request header. For example, a client request for data formatted as application/xml will receive a 406 response if the API is only willing to format data as application/json."
        case .proxyAuthenticationRequired:
            return "This is similar to 401 but authentication is needed to be done by a proxy."
        case .requestTimeout:
            return "This response is sent on an idle connection by some servers, even without any previous request by the client. It means that the server would like to shut down this unused connection. This response is used much more since some browsers, like Chrome, Firefox 27+, or IE9, use HTTP pre-connection mechanisms to speed up surfing. Also note that some servers merely shut down the connection without sending this message."
        case .conflict:
            return "This response is sent when a request conflicts with the current state of the server."
        case .gone:
            return "This response is sent when the requested content has been permanently deleted from server, with no forwarding address. Clients are expected to remove their caches and links to the resource. The HTTP specification intends this status code to be used for \"limited-time, promotional services\". APIs should not feel compelled to indicate resources that have been deleted with this status code."
        case .lengthRequired:
            return "The server refuses to accept the request without a defined Content-Length. The client MAY repeat the request if it adds a valid Content-Length header field containing the length of the message-body in the request message."
        case .preconditionFailed:
            return "The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server. This response code allows the client to place preconditions on the current resource metainformation (header field data) and thus prevent the requested method from being applied to a resource other than the one intended."
        case .payloadTooLarge:
            return "The server is refusing to process a request because the request entity is larger than the server is willing or able to process. The server MAY close the connection to prevent the client from continuing the request.\nIf the condition is temporary, the server SHOULD include a \"Retry-After\" header field to indicate that it is temporary and after what time the client MAY try again."
        case .uriTooLong:
            return "The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret. This rare condition is only likely to occur when a client has improperly converted a POST request to a GET request with long query information, when the client has descended into a URI \"black hole\" of redirection (e.g., a redirected URI prefix that points to a suffix of itself), or when the server is under attack by a client attempting to exploit security holes present in some servers using fixed-length buffers for reading or manipulating the Request-URI."
        case .unsupportedMediaType:
            return "The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method."
        case .rangeNotSatisfiable:
            return "The range specified by the Range header field in the request can't be fulfilled; it's possible that the range is outside the size of the target URI's data."
        case .expectationFailed:
            return "This response code means the expectation indicated by the Expect request header field can't be met by the server."
        case .imATeapot:
            return "The server refuses the attempt to brew coffee with a teapot."
        case .misdirectedRequest:
            return "The request was directed at a server that is not able to produce a response. This can be sent by a server that is not configured to produce responses for the combination of scheme and authority that are included in the request URI."
        case .unprocessableEntity:
            return "The request was well-formed but was unable to be followed due to semantic errors."
        case .locked:
            return "The resource that is being accessed is locked."
        case .failedDependency:
            return "The request failed due to failure of a previous request."
        case .tooEarly:
            return "Indicates that the server is unwilling to risk processing a request that might be replayed."
        case .upgradeRequired:
            return "The server refuses to perform the request using the current protocol but might be willing to do so after the client upgrades to a different protocol. The server sends an Upgrade header in a 426 response to indicate the required protocol(s)."
        case .preconditionRequired:
            return "The origin server requires the request to be conditional. This response is intended to prevent the 'lost update' problem, where a client GETs a resource's state, modifies it, and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict."
        case .tooManyRequests:
            return "The user has sent too many requests in a given amount of time (\"rate limiting\")."
        case .requestHeaderFieldsTooLarge:
            return "The server is unwilling to process the request because its header fields are too large. The request may be resubmitted after reducing the size of the request header fields."
        case .isLoginTimeout:
            return "The client's session has expired and must log in again."
        case .nginxNoResponse:
            return "A non-standard status code used to instruct nginx to close the connection without sending a response to the client, most commonly used to deny malicious or malformed requests."
        case .isRetryWith:
            return "The server cannot honour the request because the user has not provided the required information."
        case .blockedByWindowsParentalControls:
            return "The Microsoft extension code indicated when Windows Parental Controls are turned on and are blocking access to the requested webpage."
        case .unavailableForLegalReasons:
            return "The user-agent requested a resource that cannot legally be provided, such as a web page censored by a government."
        case .nginxSSLCertificateError:
            return "An expansion of the 400 Bad Request response code, used when the client has provided an invalid client certificate."
        case .nginxSSLCertificateRequired:
            return "An expansion of the 400 Bad Request response code, used when a client certificate is required but not provided."
        case .nginxHTTPToHTTPS:
            return "An expansion of the 400 Bad Request response code, used when the client has made a HTTP request to a port listening for HTTPS requests."
        case .tokenExpired:
            return "Code 498 indicates an expired or otherwise invalid token."
        case .nginxClientClosedRequest:
            return "A non-standard status code introduced by nginx for the case when a client closes the connection while nginx is processing the request."
        case .internalServerError:
            return "The server encountered an unexpected condition which prevented it from fulfilling the request."
        case .notImplemented:
            return "The server does not support the functionality required to fulfill the request. This is the appropriate response when the server does not recognize the request method and is not capable of supporting it for any resource."
        case .badGateway:
            return "The server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed in attempting to fulfill the request."
        case .serviceUnavailable:
            return "The server is currently unable to handle the request due to a temporary overloading or maintenance of the server. The implication is that this is a temporary condition which will be alleviated after some delay.\nIf known, the length of the delay MAY be indicated in a Retry-After header. If no Retry-After is given, the client SHOULD handle the response as it would for a 500 response."
        case .gatewayTimeout:
            return "The server is acting as a gateway and cannot get a response in time for a request."
        case .httpVersionNotSupported:
            return "The HTTP version used in the request is not supported by the server."
        case .variantAlsoNegotiates:
            return "Indicates that the server has an internal configuration error: the chosen variant resource is configured to engage in transparent content negotiation itself, and is therefore not a proper end point in the negotiation process."
        case .insufficientStorage:
            return "The method could not be performed on the resource because the server is unable to store the representation needed to successfully complete the request."
        case .loopDetected:
            return "The server detected an infinite loop while processing the request."
        case .bandwidthLimitExceeded:
            return "The server has exceeded the bandwidth specified by the server administrator; this is often used by shared hosting providers to limit the bandwidth of customers."
        case .notExtended:
            return "urther extensions to the request are required for the server to fulfil it."
        case .networkAuthenticationRequired:
            return "Indicates that the client needs to authenticate to gain network access."
        case .siteIsFrozen:
            return "Used by the Pantheon web platform to indicate a site that has been frozen due to inactivity."
        case .networkConnectTimeoutError:
            return "This status code is not specified in any RFCs, but is used by some HTTP proxies to signal a network connect timeout behind the proxy to a client in front of the proxy."
        }
    }
}
