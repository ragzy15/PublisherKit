//
//  Custom Combine Identifier Convertible.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

public protocol CustomCombineIdentifierConvertible {

    var combineIdentifier: CombineIdentifier { get }
}

extension CustomCombineIdentifierConvertible where Self: AnyObject {

    public var combineIdentifier: CombineIdentifier {
        CombineIdentifier(self)
    }
}
