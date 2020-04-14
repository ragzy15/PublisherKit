//
//  UITextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(UIKit)
#if !os(watchOS)

import PublisherKit
import PublisherKitFoundation
import UIKit

extension UITextView {
    
    public var textDidBeginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    public var textDidChangePublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextView)?.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidEndEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
