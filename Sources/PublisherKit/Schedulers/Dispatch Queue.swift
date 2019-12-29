//
//  Dispatch Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension DispatchQueue: NKScheduler {
    
    public func schedule(block: @escaping () -> Void) {
        async(execute: block)
    }
    
    public func schedule(after time: SchedulerTime, _ block: @escaping () -> Void) {
        asyncAfter(deadline: .now() + time.timeInterval, execute: block)
    }
}
