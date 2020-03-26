//
//  Completion Result.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/03/20.
//

enum CompletionResult<Output, Failure: Error> {
    case send(Output)
    case finished
    case failure(Failure)
}

extension CompletionResult where Output == Void {
    static var send: CompletionResult { .send(()) }
}
