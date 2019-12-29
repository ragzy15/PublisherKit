//
//  JSONDecoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NSError {

    static var publisherKitErrorDomain: String { "NKErrorDomain" }

    static func cancelled(for url: URL?) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "User cancelled the task for url: \(url?.absoluteString ?? "nil")."]
        if let url = url {
            userInfo[NSURLErrorFailingURLErrorKey] = url
        }

        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorCancelled, userInfo: userInfo)

        return error
    }

    static func badServerResponse(for url: URL) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorBadServerResponse, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "Bad server response for request : \(url.absoluteString)"
        ])

        return error
    }

    static func badURL(for urlString: String?) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorBadURL, userInfo: [
            NSURLErrorFailingURLStringErrorKey: urlString ?? "nil",
            NSLocalizedDescriptionKey: "Invalid URL provied."
        ])

        return error
    }

    static func resourceUnavailable(for url: URL) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "A requested resource couldn’t be retrieved from url: \(url.absoluteString)."
        ])

        return error
    }

    static func unsupportedURL(for url: URL?) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "A requested resource couldn’t be retrieved from url: \(url?.absoluteString ?? "nil")."]
        if let url = url {
            userInfo[NSURLErrorFailingURLErrorKey] = url
        }

        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: userInfo)

        return error
    }

    static func zeroByteResource(for url: URL) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorZeroByteResource, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "A server reported that a URL has a non-zero content length, but terminated the network connection gracefully without sending any data."
        ])

        return error
    }

    static func cannotDecodeContentData(for url: URL) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "Content data received during a connection request had an unknown content encoding."
        ])

        return error
    }

    static func cannotDecodeRawData(for url: URL) -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorCannotDecodeRawData, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSLocalizedDescriptionKey: "Content data received during a connection request had an unknown content encoding."
        ])

        return error
    }

    static func notStarted(for url: URL?) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "An asynchronous load has been canceled or not started."]
        if let url = url {
            userInfo[NSURLErrorFailingURLErrorKey] = url
        }

        let error = NSError(domain: publisherKitErrorDomain, code: NSUserCancelledError, userInfo: userInfo)

        return error
    }

    static func unkown() -> NSError {
        let error = NSError(domain: publisherKitErrorDomain, code: NSURLErrorUnknown, userInfo: [
            NSLocalizedDescriptionKey: "An Unknown Occurred."
        ])

        return error
    }
}
