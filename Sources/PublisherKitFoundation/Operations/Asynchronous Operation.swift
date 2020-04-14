//
//  Asynchronous Operation.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

open class AsynchronousOperation: Operation {
    
    override open var isAsynchronous: Bool {
        return true
    }

    private var _isFinished: Bool = false
    override open var isFinished: Bool {
        get {
            return _isFinished
        } set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    private var _isExecuting: Bool = false
    override open var isExecuting: Bool {
        get {
            return _isExecuting
        } set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    override open func start() {
        guard !isCancelled else {
            return
        }
        isExecuting = true
        main()
    }

    override open func main() {
        fatalError("Implement in sublcass to perform task")
    }

    open func finish() {
        isExecuting = false
        isFinished = true
    }
}

/* Used By Operation Queue when conforms to Scheduler protocol */
final class AsynchronousBlockOperation: AsynchronousOperation {
    
    private var block: (() -> Void)?
    private let date: OperationQueue.PKSchedulerTimeType
    private let interval: OperationQueue.PKSchedulerTimeType.Stride
    private let tolerance: OperationQueue.PKSchedulerTimeType.Stride
    private let repeats: Bool
    
    private var timer: Timer?
    
    private var stopRunLoop = false
    
    init(after date: OperationQueue.PKSchedulerTimeType, interval: OperationQueue.PKSchedulerTimeType.Stride, tolerance: OperationQueue.PKSchedulerTimeType.Stride, repeats: Bool, _ block: @escaping () -> Void) {
        self.date = date
        self.interval = interval
        self.tolerance = tolerance
        self.repeats = repeats
        self.block = block
        super.init()
    }
    
    override func start() {
        super.start()
        
        let updateInterval: TimeInterval = 0.1
        var loopUntil = Date(timeIntervalSinceNow: updateInterval)
        while !stopRunLoop && RunLoop.current.run(mode: .default, before: loopUntil) {  // keeping the run loop awake.
            loopUntil = Date(timeIntervalSinceNow: updateInterval)
        }
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        let timer = Timer(fireAt: date.date, interval: interval.timeInterval, target: self, selector: #selector(performAction), userInfo: nil, repeats: repeats)
        
        timer.tolerance = tolerance.timeInterval
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }
    
    @objc func performAction() {
        guard !isCancelled else {
            return
        }
        
        guard let timer = timer, timer.isValid else {
            return
        }
        
        block?()
        
        if !repeats {
            finish()
        }
    }
    
    override func finish() {
        stopRunLoop = true
        timer?.invalidate()
        super.finish()
        timer = nil
        block = nil
    }
    
    override func cancel() {
        stopRunLoop = true
        timer?.invalidate()
        super.cancel()
        timer = nil
        block = nil
    }
}
