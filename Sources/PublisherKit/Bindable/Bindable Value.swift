//
//  Bindable Value.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

fileprivate struct BindableObserver: Hashable {
    
    private let uuid: String
    
    let observer: NSObjectProtocol
    
    init(_ observer: NSObjectProtocol) {
        self.observer = observer
        uuid = "BindableObserver-\(UUID().uuidString)-\(Date())"
    }
    
    static func == (lhs: BindableObserver, rhs: BindableObserver) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

@propertyWrapper
public final class BindableValue<Value> {
    
    public typealias Listener = (Value) -> Void
    
    private let notificationName: Notification.Name
    
    private var observers = Set<BindableObserver>()
    
    public var wrappedValue: Value {
        didSet {
            sendNotification()
        }
    }
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        notificationName = Notification.Name("BindableValue-\(UUID().uuidString)-\(Date())")
    }
    
    public convenience init(_ wrappedValue: Value) {
        self.init(wrappedValue: wrappedValue)
    }
    
    deinit {
        removeAllObservers()
    }
    
    private func sendNotification() {
        BindableCenter.notificationCenter.post(name: notificationName, object: self, userInfo: ["value": wrappedValue])
    }
    
    public func removeAllObservers() {
        observers.forEach { (observer) in
            removeObserver(observer)
        }
        
        observers.removeAll()
    }
    
    private func removeObserver(_ observer: BindableObserver) {
        BindableCenter.notificationCenter.removeObserver(observer.observer, name: notificationName, object: self)
    }
}

extension BindableValue {
    
    public func bind(on queue: OperationQueue? = nil, to listner: @escaping Listener) {
        let notificationObserver = BindableCenter.notificationCenter.addObserver(forName: notificationName, object: self, queue: queue) { (notification) in
            guard let value = notification.userInfo?["value"] as? Value else {
                return
            }
            
            listner(value)
        }
        
        observers.insert(
            BindableObserver(notificationObserver)
        )
    }
    
    public func bind<Root>(to keypath: ReferenceWritableKeyPath<Root, Value>, on object: Root, queue: OperationQueue? = nil) {
        let notificationObserver = BindableCenter.notificationCenter.addObserver(forName: notificationName, object: self, queue: queue) { (notification) in
            guard let value = notification.userInfo?["value"] as? Value else {
                return
            }
            
            object[keyPath: keypath] = value
        }
        
        observers.insert(
            BindableObserver(notificationObserver)
        )
    }
    
    public func bindAndFire(on queue: OperationQueue? = nil, to listner: @escaping Listener) {
        bind(on: queue, to: listner)
        if let queue = queue {
            let value = wrappedValue
            queue.addOperation {
                listner(value)
            }
        } else {
            listner(wrappedValue)
        }
    }
}

extension BindableValue {
    
    public func send(_ newValue: Value, on scheduler: PKScheduler) {
        scheduler.schedule {
            self.wrappedValue = newValue
        }
    }
    
    public func send(_ newValue: Value) {
        wrappedValue = newValue
    }
    
    @available(*, deprecated, renamed: "send")
    public func set(_ newValue: Value, on scheduler: PKScheduler) {
        send(newValue, on: scheduler)
    }
    
    @available(*, deprecated, renamed: "send")
    public func set(_ newValue: Value) {
        send(newValue)
    }
}

extension BindableValue where Value == Void {
    
    public func send(on scheduler: PKScheduler) {
        scheduler.schedule {
            self.wrappedValue = ()
        }
    }
    
    public func send() {
        wrappedValue = ()
    }
}

extension BindableValue: Equatable where Value: Equatable {
    
    public static func == (lhs: BindableValue<Value>, rhs: BindableValue<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension BindableValue: Comparable where Value: Comparable {
    
    public static func < (lhs: BindableValue<Value>, rhs: BindableValue<Value>) -> Bool {
        lhs.wrappedValue < rhs.wrappedValue
    }
}

extension BindableValue: Hashable where Value: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension BindableValue: Encodable where Value: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension BindableValue: Decodable where Value: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wrappedValue = try container.decode(Value.self)
        self.init(wrappedValue: wrappedValue)
    }
}

extension BindableValue {
    
    /// The property that can be accessed with the `_` syntax and allows access to the `PKPublisher`.
    public var publisher: AnyPKPublisher<Value, Never> {
        BindableCenter.notificationCenter.pkPublisher(for: notificationName, object: self)
            .map(\.userInfo)
            .compactMap { $0?["value"] as? Value }
            .eraseToAnyPublisher()
    }
}
