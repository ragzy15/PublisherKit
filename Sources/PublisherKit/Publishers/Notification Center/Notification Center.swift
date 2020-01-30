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
    
    public struct PKPublisher: PublisherKit.PKPublisher {
        
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
        
        public func receive<S: PKSubscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            
            let notificationSubscriber = InternalSink(downstream: subscriber, center: center, name: name, object: object)
            
            notificationSubscriber.observe()
            
            notificationSubscriber.request(.unlimited)
            subscriber.receive(subscription: notificationSubscriber)
        }
    }
}

extension NotificationCenter.PKPublisher {
    
    // MARK: NOTIFICATION CENTER SINK
    private final class InternalSink<Downstream: PKSubscriber>: PKSubscribers.Sinkable<Downstream, Output, Failure> where Downstream.Failure == Failure, Downstream.Input == Output {
        
        private let center: NotificationCenter
        private let name: Notification.Name
        private let object: AnyObject?
        
        private var observer: NSObjectProtocol?
        
        init(downstream: Downstream, center: NotificationCenter, name: Notification.Name, object: AnyObject?) {
            self.center = center
            self.name = name
            self.object = object
            super.init(downstream: downstream)
        }
        
        func observe() {
            observer = center.addObserver(forName: name, object: object, queue: nil) { [weak self] (notification) in
                self?.receive(input: notification)
            }
        }
        
        override func receive(_ input: Output) -> PKSubscribers.Demand {
            guard !isCancelled else { return .none }
            downstream?.receive(input: input)
            return demand
        }
        
        override func receive(completion: PKSubscribers.Completion<Failure>) {
            guard !isCancelled else { return }
            end()
            downstream?.receive(completion: completion)
        }
        
        override func end() {
            if let observer = observer {
                center.removeObserver(observer, name: name, object: object)
            }
            observer = nil
            super.end()
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
