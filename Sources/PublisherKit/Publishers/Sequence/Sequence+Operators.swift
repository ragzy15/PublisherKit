//
//  Sequence+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers.Sequence where Failure == Never {
    
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

extension PKPublishers.Sequence {
    
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
    
    public func compactMap<T>(_ transform: (Output) -> T?) -> PKPublishers.Sequence<[T], Failure> {
        let newSequence = sequence.compactMap(transform)
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Result<Bool, Failure>.PKPublisher {
        let contains = sequence.contains(where: predicate)
        return Result.PKPublisher(contains)
    }
    
    public func tryContains(where predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        do {
            let contains = try sequence.contains(where: predicate)
            return Result.PKPublisher(contains)
        } catch {
            return Result.PKPublisher(error)
        }
    }
    
    public func drop(while predicate: (Elements.Element) -> Bool) -> PKPublishers.Sequence<DropWhileSequence<Elements>, Failure> {
        let newSequence = sequence.drop(while: predicate)
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func dropFirst(_ count: Int = 1) -> PKPublishers.Sequence<DropFirstSequence<Elements>, Failure> {
        let newSequence = sequence.dropFirst(count)
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func filter(_ isIncluded: (Output) -> Bool) -> PKPublishers.Sequence<[Output], Failure> {
        let newSequence = sequence.filter { isIncluded($0) }
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func map<T>(_ transform: (Elements.Element) -> T) -> PKPublishers.Sequence<[T], Failure> {
        let newSequence = sequence.map { transform($0) }
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(_ maxLength: Int) -> PKPublishers.Sequence<PrefixSequence<Elements>, Failure> {
        let newSequence = sequence.prefix(maxLength)
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(while predicate: (Elements.Element) -> Bool) -> PKPublishers.Sequence<[Elements.Element], Failure> {
        let newSequence = sequence.prefix(while: predicate)
        return PKPublishers.Sequence(sequence: newSequence)
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
    
    public func replaceNil<T>(with output: T) -> PKPublishers.Sequence<[Output], Failure> where Elements.Element == T? {
        let newSequence = sequence.map { (value) -> T in
            if let value = value {
                return value
            } else {
                return output
            }
        }
        
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func setFailureType<E: Error>(to error: E.Type) -> PKPublishers.Sequence<Elements, E> {
        PKPublishers.Sequence(sequence: sequence)
    }
}


extension PKPublishers.Sequence where Elements.Element: Equatable {
    
    public func removeDuplicates() -> PKPublishers.Sequence<[Output], Failure> {
        var newSequence = [Elements.Element]()
        
        sequence.forEach { (element) in
            if !newSequence.contains(element) {
                newSequence.append(element)
            }
        }
        
        return PKPublishers.Sequence(sequence: newSequence)
    }
    
    public func contains(_ output: Elements.Element) -> Result<Bool, Failure>.PKPublisher {
        let contains = sequence.contains(output)
        return Result.PKPublisher(contains)
    }
}


extension PKPublishers.Sequence where Elements.Element: Comparable, Failure == Never {
    
    public func min() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.min())
    }
    
    public func max() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.max())
    }
}

extension PKPublishers.Sequence where Elements: Collection, Failure == Never {
    
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

extension PKPublishers.Sequence where Elements: Collection {
    
    public func count() -> Result<Int, Failure>.PKPublisher {
        Result.PKPublisher(sequence.count)
    }
    
    public func output(in range: Range<Elements.Index>) -> PKPublishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return PKPublishers.Sequence(sequence: newSequence)
    }
}

extension PKPublishers.Sequence where Elements: BidirectionalCollection, Failure == Never {
    
    public func last() -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.last)
    }
    
    public func last(where predicate: (Output) -> Bool) -> Optional<Output>.PKPublisher {
        Optional.PKPublisher(sequence.last(where: predicate))
    }
}

extension PKPublishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func output(at index: Elements.Index) -> Optional<Output>.PKPublisher {
        if sequence.indices.contains(index) {
            return Optional.PKPublisher(sequence[index])
        } else {
            return Optional.PKPublisher(nil)
        }
    }
}

extension PKPublishers.Sequence where Elements: RandomAccessCollection {
    
    public func output(in range: Range<Elements.Index>) -> PKPublishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return PKPublishers.Sequence(sequence: newSequence)
    }
}

extension PKPublishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func count() -> PKPublishers.Just<Int> {
        PKPublishers.Just(sequence.count)
    }
}

extension PKPublishers.Sequence where Elements: RandomAccessCollection {
    
    public func count() -> Result<Int, Failure>.PKPublisher {
        Result.PKPublisher(sequence.count)
    }
}

extension PKPublishers.Sequence where Elements: RangeReplaceableCollection {
    
    public func prepend(_ elements: Output...) -> PKPublishers.Sequence<Elements, Failure> {
        PKPublishers.Sequence(sequence: elements + sequence)
    }
    
    public func prepend<S: Swift.Sequence>(_ elements: S) -> PKPublishers.Sequence<Elements, Failure> where Elements.Element == S.Element {
        PKPublishers.Sequence(sequence: elements + sequence)
    }
    
    public func prepend(_ publisher: PKPublishers.Sequence<Elements, Failure>) -> PKPublishers.Sequence<Elements, Failure> {
        PKPublishers.Sequence(sequence: publisher.sequence + sequence)
    }
    
    public func append(_ elements: Output...) -> PKPublishers.Sequence<Elements, Failure> {
        PKPublishers.Sequence(sequence: sequence + elements)
    }
    
    public func append<S: Sequence>(_ elements: S) -> PKPublishers.Sequence<Elements, Failure> where Elements.Element == S.Element {
        PKPublishers.Sequence(sequence: sequence + elements)
    }
    
    public func append(_ publisher: PKPublishers.Sequence<Elements, Failure>) -> PKPublishers.Sequence<Elements, Failure> {
        PKPublishers.Sequence(sequence: sequence + publisher.sequence)
    }
}

extension PKPublishers.Sequence: Equatable where Elements: Equatable {
    
    public static func == (lhs: PKPublishers.Sequence<Elements, Failure>, rhs: PKPublishers.Sequence<Elements, Failure>) -> Bool {
        lhs.sequence == rhs.sequence
    }
}
