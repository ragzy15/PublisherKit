//
//  Dispatch Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension DispatchQueue: PKScheduler {
    
    public func schedule(block: @escaping () -> Void) {
        async(execute: block)
    }
    
    public func schedule(after time: SchedulerTime, _ block: @escaping () -> Void) {
        asyncAfter(deadline: .now() + time.timeInterval, execute: block)
    }
}
