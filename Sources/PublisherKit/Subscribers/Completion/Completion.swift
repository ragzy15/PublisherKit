//
//  Completion.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

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
        
        private enum CodingKeys: String, CodingKey {
            case success
            case error
        }
    }
}

extension Subscribers.Completion: Equatable where Failure: Equatable { }

extension Subscribers.Completion: Hashable where Failure: Hashable { }

extension Subscribers.Completion: Decodable where Failure: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: .success)
        
        if success {
            self = .finished
        } else {
            let error = try container.decode(Failure.self, forKey: .error)
            self = .failure(error)
        }
    }
}


extension Subscribers.Completion: Encodable where Failure: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .finished:
            try container.encode(true, forKey: .success)
            
        case .failure(let error):
            try container.encode(false, forKey: .success)
            try container.encode(error, forKey: .error)
        }
    }
}
