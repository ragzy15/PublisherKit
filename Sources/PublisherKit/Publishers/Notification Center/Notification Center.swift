//
//  Notification Center.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NotificationCenter {
    
    public func nkPublisher(for name: Notification.Name, object: AnyObject? = nil) -> NotificationCenter.NKPublisher {
        NKPublisher(center: self, name: name, object: object)
    }
}

extension NotificationCenter {
    
    public struct NKPublisher: PublisherKit.NKPublisher {
        
        public typealias Output = Notification
        
        public typealias Failure = Never
        
        /// The notification center this publisher uses as a source.
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
        public init(center: NotificationCenter, name: Notification.Name, object: AnyObject? = nil) {
            self.center = center
            self.name = name
            self.object = object
        }
        
        public func receive<S: NKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let notificationSubscriber = NKSubscribers.TopLevelSink<S, Self>(downstream: subscriber)

            let observer = center.addObserver(forName: name, object: object, queue: nil) { (notification) in
                notificationSubscriber.receive(input: notification)
            }

            notificationSubscriber.cancelBlock = {
                self.center.removeObserver(observer, name: self.name, object: self.object)
            }
            
            notificationSubscriber.request(.unlimited)
            subscriber.receive(subscription: notificationSubscriber)
        }
    }
}
