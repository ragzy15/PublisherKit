//
//  NSObject Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

extension NSObject {
    
    final class Inner<Downstream: PKSubscriber, Subject: NSObject, Value>: SameUpstreamOperatorSink<Downstream, KeyValueObservingPKPublisher<Subject, Value>> where Downstream.Failure == Never, Downstream.Input == Value {
        
        var observer: NSKeyValueObservation?
        
        override func cancel() {
            observer?.invalidate()
            super.cancel()
        }
    }
}
