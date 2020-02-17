//
//  Optional+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

protocol OptionalDelegate {
    
    associatedtype Wrapped
    
    func unwrappedValue() -> Wrapped?
}

extension Optional: OptionalDelegate {
    
    func unwrappedValue() -> Wrapped? {
        return self
    }
}
