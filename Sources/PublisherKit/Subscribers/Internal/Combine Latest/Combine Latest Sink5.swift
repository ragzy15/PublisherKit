//
//  Comine Latest Sink5.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers.CombineLatest5 {
    
    final class InternalSink<Downstream: PKSubscriber, AInput, BInput, CInput, DInput, EInput, Failure>: ZipSink5<Downstream, AInput, BInput, CInput, DInput, EInput, Failure> where Downstream.Input == (AInput, BInput, CInput, DInput, EInput), Downstream.Failure == Failure {
        
        override func checkAndSend() {
            if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput, let dValue = dOutput, let eValue = eOutput {
                _ = receive((aValue, bValue, cValue, dValue, eValue))
            }
        }
    }
}
