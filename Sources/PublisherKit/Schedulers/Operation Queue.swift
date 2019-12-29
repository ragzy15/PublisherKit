//
//  Operation Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension OperationQueue: NKScheduler {
    
    public func schedule(block : @escaping () -> Void) {
        addOperation {
            block()
        }
    }
    
    public func schedule(after time: SchedulerTime, _ block: @escaping () -> Void) {
        let operation = AsynchronousBlockOperation(time: time, block)
        operation.completionBlock = {
            if !operation.isCancelled, !operation.executedOnCurrentThread {
                self.addOperation(block)
            }
        }
        addOperation(operation)
    }
}
