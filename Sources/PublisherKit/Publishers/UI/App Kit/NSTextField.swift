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
    
    public var textChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidChangeNotification as Notification.Name, object: self)
            .map { ($0.object as? Self)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
