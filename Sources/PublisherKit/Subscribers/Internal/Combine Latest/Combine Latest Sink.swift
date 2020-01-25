//
//  Comine Latest Sink.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers.CombineLatest {
    
    final class InternalSink<Downstream: PKSubscriber, AInput, BInput, Failure>: ZipSink<Downstream, AInput, BInput, Failure> where Downstream.Input == (AInput, BInput), Downstream.Failure == Failure {
        
        override func checkAndSend() {
            if let aValue = aOutput, let bValue = bOutput {
                _ = receive((aValue, bValue))
            }
        }
    }
}
