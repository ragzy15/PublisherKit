//
//  NSTextView.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

#if canImport(AppKit)

import AppKit

extension NSTextView {
    
    @available(*, deprecated, renamed: "textChangePublisher")
    public var nkTextPublisher: AnyPKPublisher<String, Never> {
        textChangePublisher
    }
    
    public var textChangePublisher: AnyPKPublisher<String, Never> {
        NotificationCenter.default.pkPublisher(for: NSTextView.didChangeNotification, object: self)
            .map { ($0.object as? Self)?.string ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
