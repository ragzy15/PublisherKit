//
//  Result+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

extension Result {
    
    func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Error> {
        do {
            return .success(try transform(try get()))
        } catch {
            return .failure(error)
        }
    }
}
