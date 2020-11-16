//
//  UITextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

#if canImport(UIKit)
#if !os(watchOS)

import UIKit
import Combine

extension UITextView {
    
    public var textDidBeginEditingPublisher: PublisherKit.AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    public var textDidChangePublisher: PublisherKit.AnyPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextView)?.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    public var textDidEndEditingCombinePublisher: Combine.AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UITextView.textDidEndEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
    
    public var textDidEndEditingPublisher: PublisherKit.AnyPublisher<Void, Never> {
        NotificationCenter.default.pkPublisher(for: UITextView.textDidEndEditingNotification, object: self)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
