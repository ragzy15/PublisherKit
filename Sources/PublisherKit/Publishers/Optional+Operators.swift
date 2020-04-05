//
//  Optional+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

extension Optional.PKPublisher where Output: Comparable {
    
    public func min() -> Optional<Output>.PKPublisher {
        self
    }
    
    public func max() -> Optional<Output>.PKPublisher {
        self
    }
}

extension Optional.PKPublisher where Output: Equatable {
    
    public func contains(_ output: Output) -> Optional<Bool>.PKPublisher {
        Optional<Bool>.PKPublisher(self.output == output)
    }
    
    public func removeDuplicates() -> Optional<Output>.PKPublisher {
        self
    }
}

extension Optional.PKPublisher {
    
    public func allSatisfy(_ predicate: (Output) -> Bool) -> Optional<Bool>.PKPublisher {
        Optional<Bool>.PKPublisher(output.map(predicate))
    }
    
    public func collect() -> Optional<[Output]>.PKPublisher {
        Optional<[Output]>.PKPublisher(output.map { [$0] } ?? [])
    }
    
    public func compactMap<T>(_ transform: (Output) -> T?) -> Optional<T>.PKPublisher {
        Optional<T>.PKPublisher(output.flatMap(transform))
    }
    
    public func min(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func max(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func prepend(_ elements: Output...) -> Publishers.Sequence<[Output], Failure> {
        prepend(elements)
    }
    
    public func prepend<S: Sequence>(_ elements: S) -> Publishers.Sequence<[Output], Failure> where Output == S.Element {
        Publishers.Sequence(sequence: elements + (output.map { [$0] } ?? []))
    }
    
    public func append(_ elements: Output...) -> Publishers.Sequence<[Output], Failure> {
        append(elements)
    }
    
    public func append<S: Sequence>(_ elements: S) -> Publishers.Sequence<[Output], Failure> where Output == S.Element {
        Publishers.Sequence(sequence: (output.map { [$0] } ?? []) + elements)
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Optional<Bool>.PKPublisher {
        Optional<Bool>.PKPublisher(output.map(predicate))
    }
    
    public func count() -> Optional<Int>.PKPublisher {
        Optional<Int>.PKPublisher(output.map { _ in 1 })
    }
    
    public func dropFirst(_ count: Int = 1) -> Optional<Output>.PKPublisher {
        precondition(count >= 0, "count must not be negative.")
        return Optional<Output>.PKPublisher(count > 0 ? nil : output)
    }
    
    public func drop(while predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(output.flatMap { predicate($0) ? nil : $0 })
    }
    
    public func first() -> Optional<Output>.PKPublisher {
        self
    }
    
    public func first(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(output.flatMap { predicate($0) ? $0 : nil })
    }
    
    public func last() -> Optional<Output>.PKPublisher {
        self
    }
    
    public func last(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(output.flatMap { predicate($0) ? $0 : nil })
    }
    
    public func filter(_ isIncluded: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(output.flatMap { isIncluded($0) ? $0 : nil })
    }
    
    public func ignoreOutput() -> Empty<Output, Failure> {
        Empty()
    }
    
    public func map<T>(_ transform: (Output) -> T) ->  Optional<T>.PKPublisher {
        Optional<T>.PKPublisher(output.map(transform))
    }
    
    public func output(at index: Int) -> Optional<Output>.PKPublisher {
        precondition(index >= 0, "Index must not be negative.")
        return Optional<Output>.PKPublisher(index == 0 ? output : nil)
    }
    
    public func output<R: RangeExpression>(in range: R) -> Optional<Output>.PKPublisher where R.Bound == Int {
        let range = range.relative(to: 0 ..< .max)
        precondition(range.lowerBound >= 0, "Lower Bound must not be negative.")
        precondition(range.upperBound < .max - 1)
        
        return Optional<Output>.PKPublisher(output.flatMap { (range.lowerBound == 0 && range.upperBound != 0) ? $0 : nil })
    }
    
    public func prefix(_ maxLength: Int) -> Optional<Output>.PKPublisher {
        precondition(maxLength >= 0, "maxLength must not be negative.")
        return Optional<Output>.PKPublisher(maxLength > 0 ? output : nil)
    }
    
    public func prefix(while predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(output.flatMap { predicate($0) ? $0 : nil })
    }
    
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Optional<T>.PKPublisher {
        Optional<T>.PKPublisher(output.map { nextPartialResult(initialResult, $0) })
    }
    
    public func removeDuplicates(by predicate: (Output, Output) -> Bool) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func removeDuplicates<Value: Equatable>(at keyPath: KeyPath<Output, Value>) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func removeDuplicates<Root, Value: Equatable>(at keyPath: KeyPath<Root, Value>) -> Optional<Output>.PKPublisher where Output == Root? {
        self
    }
    
    public func replaceError(with output: Output) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func replaceEmpty(with output: Output) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(self.output ?? output)
    }
    
    public func retry(_ times: Int) -> Optional<Output>.PKPublisher {
        self
    }
    
    public func scan<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Optional<T>.PKPublisher {
        Optional<T>.PKPublisher(output.map { nextPartialResult(initialResult, $0) })
    }
}
