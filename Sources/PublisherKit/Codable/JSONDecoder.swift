//
//  JSONDecoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/11/19.
//

import Foundation

extension JSONDecoder: TopLevelDecoder {
    
    public typealias Input = Data
    
    public func log(from input: Input) {
        Logger.default.printJSON(data: input)
    }
}
