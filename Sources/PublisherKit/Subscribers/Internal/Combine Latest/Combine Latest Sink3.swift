//
//  Comine Latest Sink3.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

final class CombineLatestSink3<Downstream: NKSubscriber, AInput, BInput, CInput, Failure>: ZipSink3<Downstream, AInput, BInput, CInput, Failure> where Downstream.Input == (AInput, BInput, CInput), Downstream.Failure == Failure {
    
    override func checkAndSend() {
        if let aValue = aOutput, let bValue = bOutput, let cValue = cOutput {
            _ = receive((aValue, bValue, cValue))
        }
    }
}
