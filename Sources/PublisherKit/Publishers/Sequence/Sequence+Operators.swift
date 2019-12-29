//
//  Sequence+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension NKPublishers.Sequence where Failure == Never {
    
    public func min(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.NKPublisher {
        let newSequence = sequence.min(by: areInIncreasingOrder)
        return Optional.NKPublisher(newSequence)
    }
    
    public func max(by areInIncreasingOrder: (Output, Output) -> Bool) -> Optional<Output>.NKPublisher {
        let newSequence = sequence.max(by: areInIncreasingOrder)
        return Optional.NKPublisher(newSequence)
    }
    
    public func first(where predicate: (Output) -> Bool) -> Optional<Output>.NKPublisher {
        let newSequence = sequence.first(where: predicate)
        return Optional.NKPublisher(newSequence)
    }
}

extension NKPublishers.Sequence {
    
    public func allSatisfy(_ predicate: (Output) -> Bool) -> Result<Bool, Failure>.NKPublisher {
        let result = sequence.allSatisfy(predicate)
        return Result.NKPublisher(result)
    }
    
    public func tryAllSatisfy(_ predicate: (Output) throws -> Bool) -> Result<Bool, Error>.NKPublisher {
        do {
            let result = try sequence.allSatisfy(predicate)
            return Result.NKPublisher(result)
        } catch {
            return Result.NKPublisher(error)
        }
    }
    
    public func collect() -> Result<[Output], Failure>.NKPublisher {
        let output = sequence.map { $0 }
        return Result.NKPublisher(output)
    }
    
    public func compactMap<T>(_ transform: (Output) -> T?) -> NKPublishers.Sequence<[T], Failure> {
        let newSequence = sequence.compactMap(transform)
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Result<Bool, Failure>.NKPublisher {
        let contains = sequence.contains(where: predicate)
        return Result.NKPublisher(contains)
    }
    
    public func tryContains(where predicate: (Output) throws -> Bool) -> Result<Bool, Error>.NKPublisher {
        do {
            let contains = try sequence.contains(where: predicate)
            return Result.NKPublisher(contains)
        } catch {
            return Result.NKPublisher(error)
        }
    }
    
    public func drop(while predicate: (Elements.Element) -> Bool) -> NKPublishers.Sequence<DropWhileSequence<Elements>, Failure> {
        
        let newSequence = sequence.drop(while: predicate)
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func dropFirst(_ count: Int = 1) -> NKPublishers.Sequence<DropFirstSequence<Elements>, Failure> {
        let newSequence = sequence.dropFirst(count)
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func filter(_ isIncluded: (Output) -> Bool) -> NKPublishers.Sequence<[Output], Failure> {
        
        let newSequence = sequence.filter { isIncluded($0) }
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func map<T>(_ transform: (Elements.Element) -> T) -> NKPublishers.Sequence<[T], Failure> {
        let newSequence = sequence.map { transform($0) }
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(_ maxLength: Int) -> NKPublishers.Sequence<PrefixSequence<Elements>, Failure> {
        let newSequence = sequence.prefix(maxLength)
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func prefix(while predicate: (Elements.Element) -> Bool) -> NKPublishers.Sequence<[Elements.Element], Failure> {
        let newSequence = sequence.prefix(while: predicate)
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) -> T) -> Result<T, Failure>.NKPublisher {
        let newSequence = sequence.reduce(initialResult, nextPartialResult)
        return Result.NKPublisher(newSequence)
    }
    
    public func tryReduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) throws -> T) -> Result<T, Error>.NKPublisher {
        do {
            let newSequence = try sequence.reduce(initialResult, nextPartialResult)
            return Result.NKPublisher(newSequence)
        } catch {
            return Result.NKPublisher(error)
        }
    }
    
    public func replaceNil<T>(with output: T) -> NKPublishers.Sequence<[Output], Failure> where Elements.Element == T? {
        let newSequence = sequence.map { (value) -> T in
            if let value = value {
                return value
            } else {
                return output
            }
        }
        
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func setFailureType<E: Error>(to error: E.Type) -> NKPublishers.Sequence<Elements, E> {
        NKPublishers.Sequence(sequence: sequence)
    }
}


extension NKPublishers.Sequence where Elements.Element: Equatable {
    
    public func removeDuplicates() -> NKPublishers.Sequence<[Output], Failure> {
        var newSequence = [Elements.Element]()
        
        sequence.forEach { (element) in
            if !newSequence.contains(element) {
                newSequence.append(element)
            }
        }
        
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func contains(_ output: Elements.Element) -> Result<Bool, Failure>.NKPublisher {
        
        let contains = sequence.contains(output)
        return Result.NKPublisher(contains)
    }
}


extension NKPublishers.Sequence where Elements.Element: Comparable, Failure == Never {
    
    public func min() -> Optional<Output>.NKPublisher {
        Optional.NKPublisher(sequence.min())
    }
    
    public func max() -> Optional<Output>.NKPublisher {
        Optional.NKPublisher(sequence.max())
    }
}

extension NKPublishers.Sequence where Elements: Collection, Failure == Never {
    
    public func first() -> Optional<Output>.NKPublisher {
        Optional.NKPublisher(sequence.first)
    }
    
    public func output(at index: Elements.Index) -> Optional<Output>.NKPublisher {
        if sequence.indices.contains(index) {
            return Optional.NKPublisher(sequence[index])
        } else {
            return Optional.NKPublisher(nil)
        }
    }
}

extension NKPublishers.Sequence where Elements: Collection {
    
    public func count() -> Result<Int, Failure>.NKPublisher {
        Result.NKPublisher(sequence.count)
    }
    
    public func output(in range: Range<Elements.Index>) -> NKPublishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return NKPublishers.Sequence(sequence: newSequence)
    }
}

extension NKPublishers.Sequence where Elements: BidirectionalCollection, Failure == Never {
    
    public func last() -> Optional<Output>.NKPublisher {
        Optional.NKPublisher(sequence.last)
    }
    
    public func last(where predicate: (Output) -> Bool) -> Optional<Output>.NKPublisher {
        Optional.NKPublisher(sequence.last(where: predicate))
    }
}

extension NKPublishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func output(at index: Elements.Index) -> Optional<Output>.NKPublisher {
        if sequence.indices.contains(index) {
            return Optional.NKPublisher(sequence[index])
        } else {
            return Optional.NKPublisher(nil)
        }
    }
}

extension NKPublishers.Sequence where Elements: RandomAccessCollection {
    
    public func output(in range: Range<Elements.Index>) -> NKPublishers.Sequence<[Output], Failure> {
        let newSequence = sequence[range].map { $0 }
        return NKPublishers.Sequence(sequence: newSequence)
    }
}

extension NKPublishers.Sequence where Elements: RandomAccessCollection, Failure == Never {
    
    public func count() -> NKPublishers.Just<Int> {
        NKPublishers.Just(sequence.count)
    }
}

extension NKPublishers.Sequence where Elements: RandomAccessCollection {
    
    public func count() -> Result<Int, Failure>.NKPublisher {
        Result.NKPublisher(sequence.count)
    }
}

extension NKPublishers.Sequence where Elements: RangeReplaceableCollection {
    
    //    public func prepend(_ elements: Output...) -> NKPublishers.Sequence<Elements, Failure>
    
    //    public func prepend<S: Swift.Sequence>(_ elements: S) -> NKPublishers.Sequence<Elements, Failure> where Elements.Element == S.Element
    
    //    public func prepend(_ publisher: NKPublishers.Sequence<Elements, Failure>) -> NKPublishers.Sequence<Elements, Failure>
    
    public func append(_ elements: Output...) -> NKPublishers.Sequence<Elements, Failure> {
        var newSequence = sequence
        newSequence.append(contentsOf: elements)
        
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func append<S: Sequence>(_ elements: S) -> NKPublishers.Sequence<Elements, Failure> where Elements.Element == S.Element {
        var newSequence = sequence
        newSequence.append(contentsOf: elements)
        
        return NKPublishers.Sequence(sequence: newSequence)
    }
    
    public func append(_ publisher: NKPublishers.Sequence<Elements, Failure>) -> NKPublishers.Sequence<Elements, Failure> {
        var newSequence = sequence
        newSequence.append(contentsOf: publisher.sequence)
        
        return NKPublishers.Sequence(sequence: newSequence)
    }
}

extension NKPublishers.Sequence: Equatable where Elements: Equatable {
    
    public static func == (lhs: NKPublishers.Sequence<Elements, Failure>, rhs: NKPublishers.Sequence<Elements, Failure>) -> Bool {
        lhs.sequence == rhs.sequence
    }
}
