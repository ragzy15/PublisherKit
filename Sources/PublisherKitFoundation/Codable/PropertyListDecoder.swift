//
//  PropertyListDecoder.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 04/02/20.
//

import PublisherKit
import Foundation

extension PropertyListDecoder: TopLevelDecoder {
    
    public typealias Input = Data
    
    public func log(from input: Input) {
        Logger.default.printPropertyList(data: input)
    }
}
