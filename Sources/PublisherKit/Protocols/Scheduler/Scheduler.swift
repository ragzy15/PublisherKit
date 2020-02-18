//
//  Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

@available(*, deprecated, renamed: "Scheduler")
public typealias NKScheduler = Scheduler

@available(*, deprecated, renamed: "Scheduler")
public typealias PKScheduler = Scheduler

/// A protocol that defines when and how to execute a closure.
///
/// A scheduler used to execute code as soon as possible, or after a future date.
/// Individual scheduler implementations use whatever time-keeping system makes sense for them. Schdedulers express this as their `SchedulerTimeType`. Since this type conforms to `SchedulerTimeIntervalConvertible`, you can always express these times with the convenience functions like `.milliseconds(500)`.
/// Schedulers can accept options to control how they execute the actions passed to them. These options may control factors like which threads or dispatch queues execute the actions.
public protocol Scheduler {

    /// Describes an instant in time for this scheduler.
    associatedtype PKSchedulerTimeType: Strideable where PKSchedulerTimeType.Stride : PKSchedulerTimeIntervalConvertible

    /// A type that defines options accepted by the scheduler.
    ///
    /// This type is freely definable by each `Scheduler`. Typically, operations that take a `Scheduler` parameter will also take `SchedulerOptions`.
    associatedtype PKSchedulerOptions

    /// Returns this scheduler's definition of the current moment in time.
    var now: PKSchedulerTimeType { get }

    /// Returns the minimum tolerance allowed by the scheduler.
    var minimumTolerance: PKSchedulerTimeType.Stride { get }

    /// Performs the action at the next possible opportunity.
    func schedule(options: PKSchedulerOptions?, _ action: @escaping () -> Void)

    /// Performs the action at some time after the specified date.
    func schedule(after date: PKSchedulerTimeType, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void)

    /// Performs the action at some time after the specified date, at the specified
    /// frequency, optionally taking into account tolerance if possible.
    func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable
}

extension Scheduler {

    /// Performs the action at some time after the specified date, using the scheduler’s minimum tolerance.
    public func schedule(after date: PKSchedulerTimeType, _ action: @escaping () -> Void) {
        schedule(after: date, tolerance: minimumTolerance, options: nil, action)
    }

    /// Performs the action at the next possible opportunity, without options.
    public func schedule(_ action: @escaping () -> Void) {
        schedule(options: nil, action)
    }

    /// Performs the action at some time after the specified date.
    public func schedule(after date: PKSchedulerTimeType, tolerance: PKSchedulerTimeType.Stride, _ action: @escaping () -> Void) {
        schedule(after: date, tolerance: tolerance, options: nil, action)
    }

    /// Performs the action at some time after the specified date, at the specified
    /// frequency, taking into account tolerance if possible.
    public func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, tolerance: PKSchedulerTimeType.Stride, _ action: @escaping () -> Void) -> Cancellable {
        schedule(after: date, interval: interval, tolerance: tolerance, options: nil, action)
    }

    /// Performs the action at some time after the specified date, at the specified
    /// frequency, using minimum tolerance possible for this Scheduler.
    public func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, _ action: @escaping () -> Void) -> Cancellable {
        schedule(after: date, interval: interval, tolerance: minimumTolerance, action)
    }
}

/// A protocol that provides a scheduler with an expression for relative time.
public protocol PKSchedulerTimeIntervalConvertible {

    /// Converts the specified number of seconds into an instance of this scheduler time type.
    static func seconds(_ s: Int) -> Self

    /// Converts the specified number of seconds, as a floating-point value, into an instance of this scheduler time type.
    static func seconds(_ s: Double) -> Self

    /// Converts the specified number of milliseconds into an instance of this scheduler time type.
    static func milliseconds(_ ms: Int) -> Self

    /// Converts the specified number of microseconds into an instance of this scheduler time type.
    static func microseconds(_ us: Int) -> Self

    /// Converts the specified number of nanoseconds into an instance of this scheduler time type.
    static func nanoseconds(_ ns: Int) -> Self
}
