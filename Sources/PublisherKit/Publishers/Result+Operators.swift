//
//  Result+Operators.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

extension Result.PKPublisher where Output: Comparable {
    
    public func min() -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func max() -> Result<Output, Failure>.PKPublisher {
        self
    }
}

extension Result.PKPublisher where Output: Equatable {
    
    public func contains(_ output: Output) -> Result<Bool, Failure>.PKPublisher {
        Result<Bool, Failure>.PKPublisher(result.map { $0 == output })
    }
    
    public func removeDuplicates() -> Result<Output, Failure>.PKPublisher {
        self
    }
}

extension Result.PKPublisher {
    
    public func allSatisfy(_ predicate: (Output) -> Bool) -> Result<Bool, Failure>.PKPublisher {
        Result<Bool, Failure>.PKPublisher(result.map { predicate($0) })
    }
    
    public func tryAllSatisfy(_ predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        Result<Bool, Error>.PKPublisher(result.tryMap(predicate))
    }
    
    public func collect() -> Result<[Output], Failure>.PKPublisher {
        Result<[Output], Failure>.PKPublisher(result.map { [$0] })
    }
    
    public func min(by areInIncreasingOrder: (Output, Output) -> Bool) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func max(by areInIncreasingOrder: (Output, Output) -> Bool) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func contains(where predicate: (Output) -> Bool) -> Result<Bool, Failure>.PKPublisher {
        Result<Bool, Failure>.PKPublisher(result.map(predicate))
    }
    
    public func tryContains(where predicate: (Output) throws -> Bool) -> Result<Bool, Error>.PKPublisher {
        Result<Bool, Error>.PKPublisher(result.tryMap(predicate))
    }
    
    public func count() -> Result<Int, Failure>.PKPublisher {
        Result<Int, Failure>.PKPublisher(result.map { _ in 1 })
    }
    
    public func first() -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func last() -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func ignoreOutput() -> Empty<Output, Failure> {
        Empty()
    }
    
    public func map<T>(_ transform: (Output) -> T) -> Result<T, Failure>.PKPublisher {
        Result<T, Failure>.PKPublisher(result.map(transform))
    }
    
    public func tryMap<T>(_ transform: (Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(result.tryMap(transform))
    }
    
    public func mapError<E: Error>(_ transform: (Failure) -> E) -> Result<Output, E>.PKPublisher {
        Result<Output, E>.PKPublisher(result.mapError(transform))
    }
    
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Result<T, Failure>.PKPublisher {
        Result<T, Failure>.PKPublisher(result.map { nextPartialResult(initialResult, $0) })
    }
    
    public func tryReduce<T>(_ initialResult: T, _ nextPartialResult: (T, Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(result.tryMap { try nextPartialResult(initialResult, $0) })
    }
    
    public func removeDuplicates(by predicate: (Output, Output) -> Bool) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func tryRemoveDuplicates(by predicate: (Output, Output) throws -> Bool) -> Result<Output, Error>.PKPublisher {
        Result<Output, Error>.PKPublisher(
            result.tryMap { (output) -> Output in
                _ = try predicate(output, output)
                return output
            }
        )
    }
    
    public func removeDuplicates<Value: Equatable>(at keyPath: KeyPath<Output, Value>) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func removeDuplicates<Root, Value: Equatable>(at keyPath: KeyPath<Root, Value>) -> Result<Output, Failure>.PKPublisher where Output == Root? {
        self
    }
    
    public func replaceError(with output: Output) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func replaceEmpty(with output: Output) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func retry(_ times: Int) -> Result<Output, Failure>.PKPublisher {
        self
    }
    
    public func scan<T>(_ initialResult: T, _ nextPartialResult: (T, Output) -> T) -> Result<T, Failure>.PKPublisher {
        Result<T, Failure>.PKPublisher(result.map { nextPartialResult(initialResult, $0) })
    }
    
    public func tryScan<T>(_ initialResult: T, _ nextPartialResult: (T, Output) throws -> T) -> Result<T, Error>.PKPublisher {
        Result<T, Error>.PKPublisher(result.tryMap { try nextPartialResult(initialResult, $0) })
    }
}

extension Result.PKPublisher where Failure == Never {
    
    public func setFailureType<E: Error>(to failureType: E.Type) -> Result<Output, E>.PKPublisher {
        switch result {
        case .success(let success):
            return Result<Output, E>.PKPublisher(.success(success))
        }
    }
}
