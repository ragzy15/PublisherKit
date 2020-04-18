//
//  PartialCompletion.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

enum PartialCompletion<Output, Failure: Error> {
    case `continue`(Output)
    case finished
    case failure(Failure)
}

extension PartialCompletion where Output == Void {
    static var `continue`: PartialCompletion { .continue(()) }
}
