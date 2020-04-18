//
//  Just+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 08/02/20.
//

extension Publishers.Just where Output: Comparable {
    
    public func min() -> Publishers.Just<Output> {
        self
    }
    
    public func max() -> Publishers.Just<Output> {
        self
    }
}

extension Publishers.Just where Output: Equatable {
    
    public func contains(_ output: Output) -> Publishers.Just<Bool> {
        Publishers.Just(self.output == output)
    }
    
    public func removeDuplicates() -> Publishers.Just<Output> {
        self
    }
}

extension Publishers.Just {
    
    public func allSatisfy(_ predicate: (Output) -> Bool) -> Publishers.Just<Bool> {
        Publishers.Just(predicate(output))
    }
    
    public func tryAllSatisfy(_ predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        Result<Bool, Error>.PKPublisher(Result { try predicate(output) })
    }
    
    public func collect() -> Publishers.Just<[Output]> {
        Publishers.Just([output])
    }
    
    public func compactMap<T>(_ transform: (Output) -> T?) -> Optional<T>.PKPublisher {
        Optional<T>.PKPublisher(transform(output))
    }
    
    public func min(by areInIncreasingOrder: (Output, Output) -> Bool) -> Publishers.Just<Output> {
        self
    }
    
    public func max(by areInIncreasingOrder: (Output, Output) -> Bool) -> Publishers.Just<Output> {
        self
    }
    
    public func prepend(_ elements: Output...) -> Publishers.Sequence<[Output], Failure> {
        prepend(elements)
    }
    
    public func prepend<S: Sequence>(_ elements: S) -> Publishers.Sequence<[Output], Failure> where Output == S.Element {
        Publishers.Sequence(sequence: elements + [output])
    }
    
    public func append(_ elements: Output...) -> Publishers.Sequence<[Output], Failure> {
        append(elements)
    }
    
    public func append<S: Sequence>(_ elements: S) -> Publishers.Sequence<[Output], Failure> where Output == S.Element {
        Publishers.Sequence(sequence: [output] + elements)
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Publishers.Just<Bool> {
        Publishers.Just(predicate(output))
    }
    
    public func tryContains(where predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        Result<Bool, Error>.PKPublisher(Result { try predicate(output) })
    }
    
    public func count() -> Publishers.Just<Int> {
        Publishers.Just(1)
    }
    
    public func dropFirst(_ count: Int = 1) -> Optional<Output>.PKPublisher {
        precondition(count >= 0, "count must not be negative.")
        return Optional<Output>.PKPublisher(count > 0 ? nil : output)
    }
    
    public func drop(while predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(predicate(output) ? nil : output)
    }
    
    public func first() -> Publishers.Just<Output> {
        self
    }
    
    public func first(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(predicate(output) ? output : nil)
    }
    
    public func last() -> Publishers.Just<Output> {
        self
    }
    
    public func last(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(predicate(output) ? output : nil)
    }
    
    public func filter(_ isIncluded: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(isIncluded(output) ? output : nil)
    }
    
    public func ignoreOutput() -> Empty<Output, Failure> {
        Empty()
    }
    
    public func map<T>(_ transform: (Output) -> T) -> Publishers.Just<T> {
        Publishers.Just(transform(output))
    }
    
    public func tryMap<T>(_ transform: (Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(Result { try transform(output) })
    }
    
    public func mapError<E: Error>(_ transform: (Failure) -> E) -> Result<Output, E>.PKPublisher {
        Result<Output, E>.PKPublisher(output)
    }
    
    public func output(at index: Int) -> Optional<Output>.PKPublisher {
        precondition(index >= 0, "index must not be negative.")
        return Optional<Output>.PKPublisher(index == 0 ? output : nil)
    }
    
    public func output<R: RangeExpression>(in range: R) -> Optional<Output>.PKPublisher where R.Bound == Int {
        Optional<Output>.PKPublisher(range.contains(0) ? output : nil)
    }
    
    public func prefix(_ maxLength: Int) -> Optional<Output>.PKPublisher {
        precondition(maxLength >= 0, "maxLength must not be negative.")
        return Optional<Output>.PKPublisher(maxLength > 0 ? output : nil)
    }
    
    public func prefix(while predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional<Output>.PKPublisher(predicate(output) ? output : nil)
    }
    
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Result<T, Failure>.PKPublisher {
        Result<T, Failure>.PKPublisher(nextPartialResult(initialResult, output))
    }
    
    public func tryReduce<T>(_ initialResult: T, _ nextPartialResult: (T, Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(Result { try nextPartialResult(initialResult, output) })
    }
    
    public func removeDuplicates(by predicate: (Output, Output) -> Bool) -> Publishers.Just<Output> {
        self
    }
    
    public func tryRemoveDuplicates(by predicate: (Output, Output) throws -> Bool) -> Result<Output, Error>.PKPublisher {
        Result<Output, Error>.PKPublisher(
            Result {
                try _ = predicate(output, output)
                return output
            }
        )
    }
    
    public func removeDuplicates<Value: Equatable>(at keyPath: KeyPath<Output, Value>) -> Publishers.Just<Output> {
        self
    }
    
    public func removeDuplicates<Root, Value: Equatable>(at keyPath: KeyPath<Root, Value>) -> Publishers.Just<Output> where Output == Root? {
        self
    }
    
    public func replaceError(with output: Output) -> Publishers.Just<Output> {
        self
    }
    
    public func replaceEmpty(with output: Output) -> Publishers.Just<Output> {
        self
    }
    
    public func retry(_ times: Int) -> Publishers.Just<Output> {
        self
    }
    
    public func scan<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Result<T, Failure>.PKPublisher {
        Result<T, Failure>.PKPublisher(nextPartialResult(initialResult, output))
    }
    
    public func tryScan<T>(_ initialResult: T, _ nextPartialResult: (T, Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(Result { try nextPartialResult(initialResult, output) })
    }
    
    public func setFailureType<E: Error>(to failureType: E.Type) -> Result<Output, E>.PKPublisher {
        Result<Output, E>.PKPublisher(output)
    }
}
