//
//  UITextField.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

#if canImport(UIKit)
#if !os(watchOS)

import UIKit

extension UITextField {
    
    public var nkTextPublisher: NKAnyPublisher<String, Never> {
        NotificationCenter.default.nkPublisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? Self)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}

#endif
#endif
