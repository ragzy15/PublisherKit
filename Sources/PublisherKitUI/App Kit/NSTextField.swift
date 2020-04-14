//
//  NSTextField.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if !targetEnvironment(macCatalyst)
#if canImport(AppKit)

import PublisherKit
import PublisherKitFoundation
import AppKit

extension NSTextField {
    
    public var textDidBeginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidBeginEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    public var textDidChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidChangeNotification, object: self)
            .map { ($0.object as? NSTextField)?.stringValue ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextField.textDidEndEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
