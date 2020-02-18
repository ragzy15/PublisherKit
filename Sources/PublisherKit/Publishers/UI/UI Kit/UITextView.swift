//
//  UITextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(UIKit)
#if !os(watchOS)

import UIKit

extension UITextView {
    
    @available(*, deprecated, renamed: "textChangePublisher")
    public var nkTextPublisher: AnyPublisher<String, Never> {
        textChangePublisher
    }
    
    public var textDidBeginEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .map { ($0.object as? Self)?.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidChangeNotification, object: self)
            .map { ($0.object as? Self)?.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidEndEditingNotification, object: self)
            .map { ($0.object as? Self)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
