//
//  Bindable Value.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
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
public class BindableValue<Value> {
    
    public typealias Listener = (Value) -> Void
    
    private let notificationName: Notification.Name
    
    private var observers = Set<BindableObserver>()
    
    private let uuid = UUID()
    
    public var wrappedValue: Value {
        didSet {
            BindableCenter.notificationCenter.post(name: notificationName, object: nil, userInfo: ["value": wrappedValue])
        }
    }
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        notificationName = Notification.Name("BindableObject-\(uuid)-\(Date())")
    }
    
    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        notificationName = Notification.Name("BindableObject-\(uuid)-\(Date())")
    }

    deinit {
        observers.forEach { (observer) in
            removeObsever(observer)
        }
        
        observers.removeAll()
    }
}

extension BindableValue {
    
    public func set(_ newValue: Value, on scheduler: NKScheduler) {
        scheduler.schedule {
            self.wrappedValue = newValue
        }
    }
    
    public func set(_ newValue: Value, on scheduler: DispatchQueue) {
        scheduler.schedule {
            self.wrappedValue = newValue
        }
    }
    
    public func set(_ newValue: Value) {
        self.wrappedValue = newValue
    }
}

extension BindableValue {
    
    public func bind(to listner: @escaping Listener) {
        let notificationObserver = BindableCenter.notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            listner(self.wrappedValue)
        }
        
        observers.insert(
            BindableObserver(notificationObserver)
        )
    }
    
    public func bind<Root>(to keypath: ReferenceWritableKeyPath<Root, Value>, on object: Root) {
        let notificationObserver = BindableCenter.notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            object[keyPath: keypath] = self.wrappedValue
        }
        
        observers.insert(
            BindableObserver(notificationObserver)
        )
    }
    
    public func bindAndFire(to listner: @escaping Listener) {
        bind(to: listner)
        listner(wrappedValue)
    }
    
    private func removeObsever(_ observer: BindableObserver) {
        BindableCenter.notificationCenter.removeObserver(observer.observer, name: notificationName, object: nil)
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

extension BindableValue {
    
    /// The property that can be accessed with the `_` syntax and allows access to the `Publisher`.
    public var publisher: NKAnyPublisher<Value, Never> {
        BindableCenter.notificationCenter.nkPublisher(for: notificationName)
            .map(\.userInfo)
            .compactMap { $0?["value"] as? Value }
            .eraseToAnyPublisher()
    }
}
