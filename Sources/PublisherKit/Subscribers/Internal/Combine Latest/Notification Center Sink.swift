//
//  Notification Center Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

extension NotificationCenter {
    
    final class Inner<Downstream: PKSubscriber>: SameUpstreamOperatorSink<Downstream, PKPublisher> where Downstream.Failure == PKPublisher.Failure, Downstream.Input == PKPublisher.Output {
        
        let center: NotificationCenter
        let name: Notification.Name
        let object: AnyObject?
        
        var observer: NSObjectProtocol?
        
        init(downstream: Downstream, center: NotificationCenter, name: Notification.Name, object: AnyObject?) {
            self.center = center
            self.name = name
            self.object = object
            super.init(downstream: downstream)
        }
        
        override func cancel() {
            if let observer = observer {
                center.removeObserver(observer, name: name, object: object)
            }
            observer = nil
            super.cancel()
        }
    }
}
