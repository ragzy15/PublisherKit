//
//  Completion.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

public extension Subscribers {
    
    enum Completion<Failure: Error> {
        
        case finished
        
        case failure(Failure)
        
        func mapError<NewFailure: Error>(_ transform: (Failure) -> NewFailure) -> Completion<NewFailure> {
            switch self {
            case .finished:
                return .finished
            case .failure(let error):
                let newError = transform(error)
                return .failure(newError)
            }
        }
        
        func getError() -> Failure? {
            switch self {
            case .finished:
                return nil
            case .failure(let error):
                return error
            }
        }
    }
}

extension Subscribers.Completion: Decodable where Failure: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let failure = try? container.decode(Failure.self) {
            self = .failure(failure)
        } else {
            self = .finished
        }
    }
}

extension Subscribers.Completion: Equatable, Hashable where Failure: Hashable {
    
}
