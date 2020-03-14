//
//  Operation Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension OperationQueue: Scheduler {
    
    /// The scheduler time type used by the operation queue.
    public struct PKSchedulerTimeType: Strideable, Codable, Hashable {
        
        /// The date represented by this type.
        public var date: Date
        
        /// Initializes a operation queue scheduler time with the given date.
        ///
        /// - Parameter date: The date to represent.
        public init(_ date: Date) {
            self.date = date
        }
        
        /// Returns the distance to another operation queue scheduler time.
        ///
        /// - Parameter other: Another operation queue time.
        /// - Returns: The time interval between this time and the provided time.
        public func distance(to other: PKSchedulerTimeType) -> Stride {
            let timeIntervalSince1970 =
                date > other.date
                    ? date.timeIntervalSince1970 - other.date.timeIntervalSince1970
                    : other.date.timeIntervalSince1970 - date.timeIntervalSince1970
            return PKSchedulerTimeType.Stride(timeIntervalSince1970)
        }
        
        /// Returns a operation queue scheduler time calculated by advancing this instance’s time by the given interval.
        ///
        /// - Parameter n: A time interval to advance.
        /// - Returns: A operation queue time advanced by the given interval from this instance’s time.
        public func advanced(by n: Stride) -> PKSchedulerTimeType {
            let timeIntervalSince1970 = date.timeIntervalSince1970 + n.magnitude
            return PKSchedulerTimeType(Date(timeIntervalSince1970: timeIntervalSince1970))
        }
        
        /// The interval by which operation queue times advance.
        public struct Stride: ExpressibleByFloatLiteral, Comparable, SignedNumeric, Codable, PKSchedulerTimeIntervalConvertible {
            
            public typealias FloatLiteralType = TimeInterval
            
            public typealias IntegerLiteralType = TimeInterval
            
            public typealias Magnitude = TimeInterval
            
            /// The value of this time interval in seconds.
            public var magnitude: TimeInterval
            
            /// The value of this time interval in seconds.
            public var timeInterval: TimeInterval { magnitude }
            
            /// Creates an operation queue time interval from an integer seconds value.
            ///
            /// - Parameter value: The number of seconds, as an `Int`.
            public init(integerLiteral value: TimeInterval) {
                magnitude = value
            }
            
            /// Creates an operation queue time interval from a floating-point seconds value.
            ///
            /// - Parameter value: The number of seconds, as a `TimeInterval`.
            public init(floatLiteral value: TimeInterval) {
                magnitude = value
            }
            
            /// Creates an operation queue time interval from the given time interval.
            ///
            /// - Parameter timeInterval: The number of seconds, as a `TimeInterval`.
            public init(_ timeInterval: TimeInterval) {
                magnitude = timeInterval
            }
            
            /// Creates an operation queue time interval from a binary integer type.
            ///
            /// If `exactly` cannot convert to an `Int`, the resulting time interval is `nil`.
            /// - Parameter exactly: A binary integer representing a time interval.
            public init?<T: BinaryInteger>(exactly source: T) {
                guard let value = TimeInterval(exactly: source) else { return nil }
                magnitude = value
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
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                magnitude = try container.decode(TimeInterval.self)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(magnitude)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let timeIntervalSince1970 = try container.decode(TimeInterval.self)
            date = Date(timeIntervalSince1970: timeIntervalSince1970)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSince1970)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }
    }
    
    /// Options that affect the operation of the operation queue scheduler.
    public struct PKSchedulerOptions {
    }
    
    public var now: PKSchedulerTimeType { PKSchedulerTimeType(Date(timeIntervalSinceNow: 0)) }
    
    public var minimumTolerance: PKSchedulerTimeType.Stride { .seconds(0) }
    
    public func schedule(options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        addOperation(BlockOperation(block: action))
    }
    
    public func schedule(after date: PKSchedulerTimeType, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        let op = AsynchronousBlockOperation(after: date, interval: 0, tolerance: tolerance, repeats: false, action)
        addOperation(op)
    }
    
    public func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let op = AsynchronousBlockOperation(after: date, interval: interval, tolerance: tolerance, repeats: true, action)
        addOperation(op)
        return AnyCancellable(cancel: op.cancel)
    }
}
