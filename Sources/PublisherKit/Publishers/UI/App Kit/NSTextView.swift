//
//  NSTextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(AppKit)

import AppKit

extension NSTextView {
    
    @available(*, deprecated, renamed: "textChangePublisher")
    public var nkTextPublisher: AnyPublisher<String, Never> {
        textChangePublisher
    }
    
    public var textDidBeginEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didBeginEditingNotification, object: self)
            .map { ($0.object as? Self)?.string ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didChangeNotification, object: self)
            .map { ($0.object as? Self)?.string ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didEndEditingNotification, object: self)
            .map { ($0.object as? Self)?.string ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
