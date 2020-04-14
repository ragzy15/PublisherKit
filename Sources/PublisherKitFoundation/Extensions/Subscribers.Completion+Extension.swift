//
//  File.swift
//  
//
//  Created by Raghav Ahuja on 06/04/20.
//

import PublisherKit

extension Subscribers.Completion {
    func eraseError() -> Subscribers.Completion<Error> {
        switch self {
        case .finished: return .finished
        case .failure(let error): return .failure(error)
        }
    }
}
