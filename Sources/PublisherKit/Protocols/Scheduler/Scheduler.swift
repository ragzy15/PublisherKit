//
//  Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

@available(*, deprecated, renamed: "Scheduler")
public typealias NKScheduler = Scheduler

@available(*, deprecated, renamed: "Scheduler")
public typealias PKScheduler = Scheduler

public protocol Scheduler: class {
    
    func schedule(after time: SchedulerTime, _ block: @escaping () -> Void)
    func schedule(block: @escaping () -> Void)
}
