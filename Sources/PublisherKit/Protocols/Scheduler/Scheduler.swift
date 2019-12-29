//
//  Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public protocol NKScheduler: class {
    
    func schedule(after time: SchedulerTime, _ block: @escaping () -> Void)
    func schedule(block: @escaping () -> Void)
}
