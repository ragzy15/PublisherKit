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
    public var nkTextPublisher: AnyPKPublisher<String, Never> {
        textChangePublisher
    }
    
    public var textChangePublisher: AnyPKPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidChangeNotification, object: self)
            .map { ($0.object as? Self)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
