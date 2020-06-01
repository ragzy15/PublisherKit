//
//  Published.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 29/03/20.
//

/// Adds a `Publisher` to a property.
///
/// Properties annotated with `@Published` contain both the stored value and a publisher which sends any new values after the property value has been sent. New subscribers will receive the current value of the property first.
/// Note that the `@Published` property is class-constrained. Use it with properties of classes, not with non-class types like structures.
@propertyWrapper public struct Published<Value> {
    
    private var value: Value
    
    @available(*, unavailable, message: "@Published is only available on properties of classes")
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    private var publisher: Publisher?
    var objectWillChange: ObservableObjectPublisher?

    /// Initialize the storage of the Published property as well as the corresponding `Publisher`.
    public init(initialValue: Value) {
        value = initialValue
    }
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    /// A publisher for properties marked with the `@Published` attribute.
    public struct Publisher: PublisherKit.Publisher {

        public typealias Output = Value

        public typealias Failure = Never
        
        fileprivate let subject: CurrentValueSubject<Value, Never>

        fileprivate init(_ output: Output) {
            subject = CurrentValueSubject(output)
        }

        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
            subject.subscribe(subscriber)
        }
    }

    /// The property that can be accessed with the `$` syntax and allows access to the `Publisher`
    public var projectedValue: Publisher {
        mutating get {
            if let publisher = publisher {
                return publisher
            }
            
            let publisher = Publisher(value)
            self.publisher = publisher
            
            return publisher
        }
    }
    
    public static subscript<EnclosingSelf: AnyObject>(_enclosingInstance object: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Published<Value>>) -> Value {
        get {
            object[keyPath: storageKeyPath].value
        } set {
            object[keyPath: storageKeyPath].objectWillChange?.send()
            object[keyPath: storageKeyPath].publisher?.subject.send(newValue)
            object[keyPath: storageKeyPath].value = newValue
        }
    }
}
