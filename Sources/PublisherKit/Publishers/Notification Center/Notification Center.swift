//
//  Notification Center.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension NotificationCenter {
    
    public func pkPublisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenter.PKPublisher {
        PKPublisher(center: self, name: name, object: object)
    }
    
    @available(*, deprecated, renamed: "pkPublisher")
    public func nkPublisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenter.PKPublisher {
        pkPublisher(for: name, object: object)
    }
}

extension NotificationCenter {
    
    public struct PKPublisher: PublisherKit.Publisher {
        
        public typealias Output = Notification
        
        public typealias Failure = Never
        
        /// The notification center used by this publisher.
        public let center: NotificationCenter
        
        /// The name of notifications published by this publisher.
        public let name: Notification.Name
        
        /// The object posting the named notfication.
        public let object: AnyObject?
        
        /// Creates a publisher that emits events when broadcasting notifications.
        ///
        /// - Parameters:
        ///   - center: The notification center to publish notifications for.
        ///   - name: The name of the notification to publish.
        ///   - object: The object posting the named notfication. If `nil`, the publisher emits elements for any object producing a notification with the given name.
        ///   - queue: The operation queue to which block should be added.
        ///   If you pass nil, the block is run synchronously on the posting thread. Default value is nil.
        public init(center: NotificationCenter, name: Notification.Name, object: AnyObject? = nil) {
            self.center = center
            self.name = name
            self.object = object
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let notificationSubscriber = Inner(downstream: subscriber, center: center, name: name, object: object)
            
            subscriber.receive(subscription: notificationSubscriber)
            
            notificationSubscriber.observe()
        }
    }
}

extension NotificationCenter.PKPublisher {
    
    // MARK: NOTIFICATION CENTER SINK
    private final class Inner<Downstream: Subscriber>: Subscriptions.Internal<Downstream, Output, Failure> where Downstream.Failure == Failure, Downstream.Input == Output {
        
        private var center: NotificationCenter?
        private let name: Notification.Name
        private var object: AnyObject?
        
        private var observer: NSObjectProtocol?
        
        init(downstream: Downstream, center: NotificationCenter, name: Notification.Name, object: AnyObject?) {
            self.center = center
            self.name = name
            self.object = object
            super.init(downstream: downstream)
        }
        
        func observe() {
            observer = center?.addObserver(forName: name, object: object, queue: nil) { [weak self] (notification) in
                self?.receive(input: notification)
            }
        }
        
        override func cancel() {
            super.cancel()
            
            if let observer = observer {
                center?.removeObserver(observer, name: name, object: object)
            }
            
            observer = nil
            object = nil
            center = nil
        }
        
        override var description: String {
            "NotificationCenter Observer"
        }
        
        override var customMirror: Mirror {
            Mirror(self, children: [])
        }
    }
}
