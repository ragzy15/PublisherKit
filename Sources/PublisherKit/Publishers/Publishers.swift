//
//  Publishers.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

@available(*, deprecated, renamed: "Publishers")
public typealias NKPublishers = Publishers

@available(*, deprecated, renamed: "Publishers")
public typealias PKPublishers = Publishers

/// A namespace for types related to the [Publisher](apple-reference-documentation://hsja-BzNqj) protocol.
///
/// The various operators defined as extensions on `Publisher` implement their functionality as classes or structures that extend this enumeration. For example, the `contains()` operator returns a `Publishers.Contains` instance.
public struct Publishers {
}
