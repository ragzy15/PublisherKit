//
//  Comine Latest Sink3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension PKPublishers.CombineLatest3 {
    
    final class InternalSink<Downstream: PKSubscriber, AInput, BInput, CInput, Failure>: ZipSink3<Downstream, AInput, BInput, CInput, Failure> where Downstream.Input == (AInput, BInput, CInput), Downstream.Failure == Failure {
        
        override func checkAndSend() {
            if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput {
                _ = receive((aValue, bValue, cValue))
            }
        }
    }
}
