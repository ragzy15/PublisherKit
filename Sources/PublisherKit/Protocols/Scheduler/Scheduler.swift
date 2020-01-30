//
//  Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

@available(*, deprecated, renamed: "PKScheduler")
public typealias NKScheduler = PKScheduler

public protocol PKScheduler: class {
    
    func schedule(after time: SchedulerTime, _ block: @escaping () -> Void)
    func schedule(block: @escaping () -> Void)
}
