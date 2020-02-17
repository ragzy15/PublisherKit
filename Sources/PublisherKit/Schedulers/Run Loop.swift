//
//  Run Loop.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/02/20.
//

import Foundation

extension RunLoop: Scheduler {
    
    /// The scheduler time type used by the run loop.
    public struct PKStrideType: Strideable, Codable, Hashable {
        
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
        public func distance(to other: PKStrideType) -> PKStrideType.Stride {
            let timeIntervalSince1970 = date > other.date ? date.timeIntervalSince1970 - other.date.timeIntervalSince1970 : other.date.timeIntervalSince1970 - date.timeIntervalSince1970
            
            return PKStrideType.Stride(timeIntervalSince1970)
        }
        
        /// Returns a run loop scheduler time calculated by advancing this instance’s time by the given interval.
        ///
        /// - Parameter n: A time interval to advance.
        /// - Returns: A dispatch queue time advanced by the given interval from this instance’s time.
        public func advanced(by n: PKStrideType.Stride) -> PKStrideType {
            let timeIntervalSince1970 = date.timeIntervalSince1970 + n.magnitude
            return PKStrideType(Date(timeIntervalSince1970: timeIntervalSince1970))
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
            
            public init(integerLiteral value: TimeInterval) {
                magnitude = value
            }
            
            public init(floatLiteral value: TimeInterval) {
                magnitude = value
            }
            
            public init(_ timeInterval: TimeInterval) {
                magnitude = timeInterval
            }
            
            public init?<T>(exactly source: T) where T : BinaryInteger {
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
    
    public func schedule(options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        let timer = Timer(fireAt: now.date, interval: 0, target: self, selector: #selector(scheduledAction(_:)), userInfo: action, repeats: false)
        
        add(timer, forMode: .default)
    }
    
    public func schedule(after date: PKStrideType, tolerance: PKStrideType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        let timer = Timer(fireAt: date.date, interval: 0, target: self, selector: #selector(scheduledAction(_:)), userInfo: action, repeats: false)
        
        timer.tolerance = tolerance.timeInterval
        
        add(timer, forMode: .default)
    }
    
    public func schedule(after date: PKStrideType, interval: PKStrideType.Stride, tolerance: PKStrideType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let timer = Timer(fireAt: date.date, interval: interval.timeInterval, target: self, selector: #selector(scheduledAction(_:)), userInfo: action, repeats: true)
        
        timer.tolerance = tolerance.timeInterval
        
        add(timer, forMode: .default)
        
        return AnyCancellable(cancel: timer.invalidate)
    }
    
    public var now: PKStrideType { PKStrideType(Date()) }
    
    public var minimumTolerance: PKStrideType.Stride { .seconds(0) }
    
    @objc private func scheduledAction(_ timer: Timer) {
        if timer.isValid {
            let action = timer.userInfo as? () -> Void
            action?()
        }
    }
}
