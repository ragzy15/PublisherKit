//
//  Asynchronous Operation.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public class AsynchronousOperation: Operation {
    
    override public var isAsynchronous: Bool {
        return true
    }

    private var _isFinished: Bool = false
    override public var isFinished: Bool {
        get {
            return _isFinished
        } set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    private var _isExecuting: Bool = false
    override public var isExecuting: Bool {
        get {
            return _isExecuting
        } set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    override public func start() {
        guard !isCancelled else {
            return
        }
        isExecuting = true
        main()
    }

    override public func main() {
        fatalError("Implement in sublcass to perform task")
    }

    public func finish() {
        isExecuting = false
        isFinished = true
    }
}


class AsynchronousBlockOperation: AsynchronousOperation {
    
    let block: () -> Void
    let time: SchedulerTime
    
    private(set) var executedOnCurrentThread = false
    
    init(time: SchedulerTime, _ block: @escaping () -> Void) {
        self.time = time
        self.block = block
        super.init()
    }
    
    override func main() {
        let deadline = DispatchTime.now() + time.timeInterval
        
        if let queue = OperationQueue.current?.underlyingQueue {
            executedOnCurrentThread = true
            queue.asyncAfter(deadline: deadline) {
                if self.isCancelled { return }
                self.block()
                self.finish()
            }
        } else {
            executedOnCurrentThread = false
            let qos = OperationQueue.current?.qualityOfService.dispatchQos ?? .unspecified
            DispatchQueue.global(qos: qos).asyncAfter(deadline: deadline) {
                self.finish()
            }
        }
    }
}

extension QualityOfService {
    
    var dispatchQos: DispatchQoS.QoSClass {
        switch self {
        case .userInteractive:
            return .userInteractive
        case .userInitiated:
            return .userInitiated
        case .utility:
            return .utility
        case .background:
            return .background
        case .default:
            return .default
            
        @unknown default:
            return .unspecified
        }
    }
}
