//
//  Operation Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension OperationQueue: Scheduler {
    
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
