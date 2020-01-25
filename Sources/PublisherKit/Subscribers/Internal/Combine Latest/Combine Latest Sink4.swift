//
//  Comine Latest Sink4.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension PKPublishers.CombineLatest4 {

    final class CombineLatestSink4<Downstream: PKSubscriber, AInput, BInput, CInput, DInput, Failure>: ZipSink4<Downstream, AInput, BInput, CInput, DInput, Failure> where Downstream.Input == (AInput, BInput, CInput, DInput), Downstream.Failure == Failure {
        
        override func checkAndSend() {
            if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput, let dValue = dOutput {
                _ = receive((aValue, bValue, cValue, dValue))
            }
        }
    }
}
