//
//  NSTextField.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(AppKit)

import AppKit

extension NSTextField {
    
    @available(*, deprecated, renamed: "textChangePublisher")
    public var nkTextPublisher: AnyPublisher<String, Never> {
        textChangePublisher
    }
    
    public var textDidBeginEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidBeginEditingNotification, object: self)
            .map { ($0.object as? Self)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidChangeNotification, object: self)
            .map { ($0.object as? Self)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidEndEditingNotification, object: self)
            .map { ($0.object as? Self)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
