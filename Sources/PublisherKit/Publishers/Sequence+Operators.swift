//
//  Sequence+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

extension Publishers.Sequence where Failure == Never {
    
    public func min(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.PKPublisher {
        let newSequence = sequence.min(by: areInIncreasingOrder)
        return Optional.PKPublisher(newSequence)
    }
    
    public func max(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.PKPublisher {
        let newSequence = sequence.max(by: areInIncreasingOrder)
        return Optional.PKPublisher(newSequence)
    }
    
    public func first(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        let newSequence = sequence.first(where: predicate)
        return Optional.PKPublisher(newSequence)
    }
}

extension Publishers.Sequence {
    
    public func allSatisfy(_ predicate: (Output) -> Bool) -> Result<Bool, Failure>.PKPublisher {
        let result = sequence.allSatisfy(predicate)
        return Result.PKPublisher(result)
    }
    
    public func tryAllSatisfy(_ predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        do {
            let result = try sequence.allSatisfy(predicate)
            return Result.PKPublisher(result)
        } catch {
            return Result.PKPublisher(error)
        }
    }
    
    public func collect() -> Result<[Output], Failure>.PKPublisher {
        let output = sequence.map { $0 }
        return Result.PKPublisher(output)
    }
    
    public func compactMap<T>(_ transform: (Output) -> T?) -> Publishers.Sequence<[T], Failure> {
        let newSequence = sequence.compactMap(transform)
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Result<Bool, Failure>.PKPublisher {
        let contains = sequence.contains(where: predicate)
        return Result.PKPublisher(contains)
    }
    
    public func tryContains(where predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        Result<Bool, Error>.PKPublisher(Result { try sequence.contains(where: predicate) })
    }
    
    public func drop(while predicate: (Elements.Element) -> Bool) -> Publishers.Sequence<DropWhileSequence<Elements>, Failure> {
        let newSequence = sequence.drop(while: predicate)
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func dropFirst(_ count: Int = 1) -> Publishers.Sequence<DropFirstSequence<Elements>, Failure> {
        let newSequence = sequence.dropFirst(count)
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func filter(_ isIncluded: (Output) -> Bool) -> Publishers.Sequence<[Output], Failure> {
        let newSequence = sequence.filter { isIncluded($0) }
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func ignoreOutput() -> Empty<Output, Failure> {
        Empty(completeImmediately: true)
    }
    
    public func map<T>(_ transform: (Elements.Element) -> T) -> Publishers.Sequence<[T], Failure> {
        let newSequence = sequence.map { transform($0) }
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(_ maxLength: Int) -> Publishers.Sequence<PrefixSequence<Elements>, Failure> {
        let newSequence = sequence.prefix(maxLength)
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(while predicate: (Elements.Element) -> Bool) -> Publishers.Sequence<[Elements.Element], Failure> {
        let newSequence = sequence.prefix(while: predicate)
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) -> T) -> Result<T, Failure>.PKPublisher {
        let newSequence = sequence.reduce(initialResult, nextPartialResult)
        return Result.PKPublisher(newSequence)
    }
    
    public func tryReduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) throws -> T) -> Result<T, Error>.PKPublisher {
        do {
            let newSequence = try sequence.reduce(initialResult, nextPartialResult)
            return Result.PKPublisher(newSequence)
        } catch {
            return Result.PKPublisher(error)
        }
    }
    
    public func replaceNil<T>(with output: T) -> Publishers.Sequence<[Output], Failure> where Elements.Element == T? {
        let newSequence = sequence.map { $0 ?? output }
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func scan<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) -> T) -> Publishers.Sequence<[T], Failure> {
        var result = initialResult
        let newSequence = sequence.map { (element) -> T in
            result = nextPartialResult(result, element)
            return result
        }
        
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func setFailureType<E: Error>(to error: E.Type) -> Publishers.Sequence<Elements, E> {
        Publishers.Sequence(sequence: sequence)
    }
}


extension Publishers.Sequence where Elements.Element: Equatable {
    
    public func removeDuplicates() -> Publishers.Sequence<[Output], Failure> {
        var newSequence = [Elements.Element]()
        
        sequence.forEach { (element) in
            if !newSequence.contains(element) {
                newSequence.append(element)
            }
        }
        
        return Publishers.Sequence(sequence: newSequence)
    }
    
    public func contains(_ output: Elements.Element) -> Result<Bool, Failure>.PKPublisher {
        Result.PKPublisher(sequence.contains(output))
    }
}


extension Publishers.Sequence where Elements.Element: Comparable, Failure == Never {
    
    public func min() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.min())
    }
    
    public func max() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.max())
    }
}

extension Publishers.Sequence where Elements: Collection, Failure == Never {
    
    public func first() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.first)
    }
    
    public func output(at index: Elements.Index) -> Optional<Output>.PKPublisher {
        if sequence.indices.contains(index) {
            return Optional.PKPublisher(sequence[index])
        } else {
            return Optional.PKPublisher(nil)
        }
    }
}

extension Publishers.Sequence where Elements: Collection {
    
    public func count() -> Result<Int, Failure>.PKPublisher {
        Result.PKPublisher(sequence.count)
    }
    
    public func output(in range: Range<Elements.Index>) -> Publishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return Publishers.Sequence(sequence: newSequence)
    }
}

extension Publishers.Sequence where Elements: BidirectionalCollection, Failure == Never {
    
    public func last() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.last)
    }
    
    public func last(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.last(where: predicate))
    }
}

extension Publishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func output(at index: Elements.Index) -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.indices.contains(index) ? sequence[index] : nil)
    }
}

extension Publishers.Sequence where Elements: RandomAccessCollection {
    
    public func output(in range: Range<Elements.Index>) -> Publishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return Publishers.Sequence(sequence: newSequence)
    }
}

extension Publishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func count() -> Publishers.Just<Int> {
        Publishers.Just(sequence.count)
    }
}

extension Publishers.Sequence where Elements: RandomAccessCollection {
    
    public func count() -> Result<Int, Failure>.PKPublisher {
        Result.PKPublisher(sequence.count)
    }
}

extension Publishers.Sequence where Elements: RangeReplaceableCollection {
    
    public func prepend(_ elements: Output...) -> Publishers.Sequence<Elements, Failure> {
        prepend(elements)
    }
    
    public func prepend<S: Swift.Sequence>(_ elements: S) -> Publishers.Sequence<Elements, Failure> where Elements.Element == S.Element {
        Publishers.Sequence(sequence: elements + sequence)
    }
    
    public func prepend(_ publisher: Publishers.Sequence<Elements, Failure>) -> Publishers.Sequence<Elements, Failure> {
        Publishers.Sequence(sequence: publisher.sequence + sequence)
    }
    
    public func append(_ elements: Output...) -> Publishers.Sequence<Elements, Failure> {
        append(elements)
    }
    
    public func append<S: Sequence>(_ elements: S) -> Publishers.Sequence<Elements, Failure> where Elements.Element == S.Element {
        Publishers.Sequence(sequence: sequence + elements)
    }
    
    public func append(_ publisher: Publishers.Sequence<Elements, Failure>) -> Publishers.Sequence<Elements, Failure> {
        Publishers.Sequence(sequence: sequence + publisher.sequence)
    }
}

extension Publishers.Sequence: Equatable where Elements: Equatable {
    
    public static func == (lhs: Publishers.Sequence<Elements, Failure>, rhs: Publishers.Sequence<Elements, Failure>) -> Bool {
        lhs.sequence == rhs.sequence
    }
}
