//
//  Run Loop.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/02/20.
//

import PublisherKit
import Foundation

extension RunLoop: Scheduler {
    
    /// The scheduler time type used by the run loop.
    public struct PKSchedulerTimeType: Strideable, Codable, Hashable {
        
        /// The date represented by this type.
        public var date: Date
        
        /// Initializes a run loop scheduler time with the given date.
        ///
        /// - Parameter date: The date to represent.
        public init(_ date: Date) {
            self.date = date
        }
        
        /// Returns the distance to another run loop scheduler time.
        ///
        /// - Parameter other: Another dispatch queue time.
        /// - Returns: The time interval between this time and the provided time.
        public func distance(to other: PKSchedulerTimeType) -> Stride {
            let timeIntervalSince1970 =
                date > other.date
                    ? date.timeIntervalSince1970 - other.date.timeIntervalSince1970
                    : other.date.timeIntervalSince1970 - date.timeIntervalSince1970
            
            return Stride(timeIntervalSince1970)
        }
        
        /// Returns a run loop scheduler time calculated by advancing this instance’s time by the given interval.
        ///
        /// - Parameter n: A time interval to advance.
        /// - Returns: A dispatch queue time advanced by the given interval from this instance’s time.
        public func advanced(by n: Stride) -> PKSchedulerTimeType {
            let timeIntervalSince1970 = date.timeIntervalSince1970 + n.magnitude
            return PKSchedulerTimeType(Date(timeIntervalSince1970: timeIntervalSince1970))
        }
        
        /// The interval by which run loop times advance.
        public struct Stride: ExpressibleByFloatLiteral, Comparable, SignedNumeric, Codable, PKSchedulerTimeIntervalConvertible {
            
            public typealias FloatLiteralType = TimeInterval
            
            public typealias IntegerLiteralType = TimeInterval
            
            public typealias Magnitude = TimeInterval
            
            /// The value of this time interval in seconds.
            public var magnitude: TimeInterval
            
            /// The value of this time interval in seconds.
            public var timeInterval: TimeInterval { magnitude }
            
            /// Creates a run loop time interval from an integer seconds value.
            ///
            /// - Parameter value: The number of seconds, as an `Int`.
            public init(integerLiteral value: TimeInterval) {
                magnitude = value
            }
            
            /// Creates a run loop time interval from a floating-point seconds value.
            ///
            /// - Parameter value: The number of seconds, as a `TimeInterval`.
            public init(floatLiteral value: TimeInterval) {
                magnitude = value
            }
            
            /// Creates a run loop time interval from the given time interval.
            ///
            /// - Parameter timeInterval: The number of seconds, as a `TimeInterval`.
            public init(_ timeInterval: TimeInterval) {
                magnitude = timeInterval
            }
            
            /// Creates a run loop time interval from a binary integer type.
            ///
            /// If `exactly` cannot convert to an `Int`, the resulting time interval is `nil`.
            /// - Parameter exactly: A binary integer representing a time interval.
            public init?<T: BinaryInteger>(exactly source: T) {
                guard let value = TimeInterval(exactly: source) else { return nil }
                magnitude = value
            }
            
            public static func seconds(_ s: Int) -> Stride {
                Stride(TimeInterval(s))
            }
            
            public static func seconds(_ s: Double) -> Stride {
                Stride(s)
            }
            
            public static func milliseconds(_ ms: Int) -> Stride {
                Stride(TimeInterval(ms / 1_000))
            }
            
            public static func microseconds(_ us: Int) -> Stride {
                Stride(TimeInterval(us / 1_000_000))
            }
            
            public static func nanoseconds(_ ns: Int) -> Stride {
                Stride(TimeInterval(ns / 1_000_000_000))
            }
            
            public static func < (lhs: Stride, rhs: Stride) -> Bool {
                lhs.magnitude < rhs.magnitude
            }
            
            public static func * (lhs: Stride, rhs: Stride) -> Stride {
                Stride(lhs.magnitude * rhs.magnitude)
            }
            
            public static func + (lhs: Stride, rhs: Stride) -> Stride {
                Stride(lhs.magnitude + rhs.magnitude)
            }
            
            public static func - (lhs: Stride, rhs: Stride) -> Stride {
                Stride(lhs.magnitude - rhs.magnitude)
            }
            
            public static func *= (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude *= rhs.magnitude
            }
            
            public static func += (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude += rhs.magnitude
            }
            
            public static func -= (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude -= rhs.magnitude
            }
            
            public static func == (a: Stride, b: Stride) -> Bool {
                a.magnitude == b.magnitude
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                magnitude = try container.decode(TimeInterval.self)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(magnitude)
            }
        }
    }
    
    /// Options that affect the operation of the run loop scheduler.
    public struct PKSchedulerOptions {
    }
    
    public var now: PKSchedulerTimeType { PKSchedulerTimeType(Date()) }
    
    public var minimumTolerance: PKSchedulerTimeType.Stride { .seconds(0) }
    
    public func schedule(options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        let cfRunLoop = getCFRunLoop()
        CFRunLoopPerformBlock(cfRunLoop, CFRunLoopMode.defaultMode.rawValue, action)
        CFRunLoopWakeUp(cfRunLoop)
    }
    
    public func schedule(after date: PKSchedulerTimeType, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        perform(#selector(runLoopPKScheduled(action:)), with: _PKCombineRunLoopAction(action: action), afterDelay: date.date.timeIntervalSinceNow)
    }
    
    public func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        
        let timer: Timer
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            timer = Timer(fire: date.date, interval: interval.timeInterval, repeats: true) { (timer) in
                if timer.isValid {
                    action()
                }
            }
        } else {
            timer = Timer(fireAt: date.date, interval: interval.timeInterval, target: self, selector: #selector(runLoopPKScheduled(timer:)), userInfo: action, repeats: true)
        }
        
        timer.tolerance = tolerance.timeInterval
        
        add(timer, forMode: .default)
        
        return AnyCancellable(timer.invalidate)
    }
    
    @objc private func runLoopPKScheduled(timer: Timer) {
        if timer.isValid {
            let action = timer.userInfo as? () -> Void
            action?()
        }
    }
    
    @objc private func runLoopPKScheduled(action: _PKCombineRunLoopAction) {
        action.action()
    }
    
    private class _PKCombineRunLoopAction: NSObject {
        
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
            super.init()
        }
    }
}
