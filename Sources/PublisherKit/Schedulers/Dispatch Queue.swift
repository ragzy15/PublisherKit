//
//  Dispatch Queue.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//

import Foundation

extension DispatchQueue: Scheduler {
    
    /// The scheduler time type used by the dispatch queue.
    public struct PKSchedulerTimeType: Strideable, Codable, Hashable {
        
        /// The dispatch time represented by this type.
        public var dispatchTime: DispatchTime
        
        /// Creates a dispatch queue time type instance.
        ///
        /// - Parameter time: The dispatch time to represent.
        public init(_ time: DispatchTime) {
            dispatchTime = time
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            dispatchTime = try .init(uptimeNanoseconds: container.decode(UInt64.self))
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(dispatchTime.uptimeNanoseconds)
        }
        
        /// Returns the distance to another dispatch queue time.
        ///
        /// - Parameter other: Another dispatch queue time.
        /// - Returns: The time interval between this time and the provided time.
        public func distance(to other: PKSchedulerTimeType) -> PKSchedulerTimeType.Stride {
            let start = dispatchTime.rawValue
            let end = other.dispatchTime.rawValue
            return .nanoseconds(
                end >= start
                    ? Int(Int64(bitPattern: end) - Int64(bitPattern: start))
                    : -Int(Int64(bitPattern: start) - Int64(bitPattern: end))
            )
        }
        
        /// Returns a dispatch queue scheduler time calculated by advancing this instance’s time by the given interval.
        ///
        /// - Parameter n: A time interval to advance.
        /// - Returns: A dispatch queue time advanced by the given interval from this instance’s time.
        public func advanced(by n: PKSchedulerTimeType.Stride) -> PKSchedulerTimeType {
            return n.magnitude == .max
                ? .init(.distantFuture)
                : .init(dispatchTime + n.timeInterval)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(dispatchTime.rawValue)
        }
        
        /// A type that represents the distance between two values.
        public struct Stride: PKSchedulerTimeIntervalConvertible, Comparable, SignedNumeric, ExpressibleByFloatLiteral, Hashable, Codable {
            
            /// If created via floating point literal, the value is converted to nanoseconds via multiplication.
            public typealias FloatLiteralType = Double
            
            /// Nanoseconds, same as DispatchTimeInterval.
            public typealias IntegerLiteralType = Int
            
            /// A type that can represent the absolute value of any possible value of the
            /// conforming type.
            public typealias Magnitude = Int
            
            /// The value of this time interval in nanoseconds.
            public var magnitude: Int
            
            /// A `DispatchTimeInterval` created with the value of this type in nanoseconds.
            public var timeInterval: DispatchTimeInterval { .nanoseconds(magnitude) }
            
            /// Creates a dispatch queue time interval from the given dispatch time interval.
            ///
            /// - Parameter timeInterval: A dispatch time interval.
            public init(_ timeInterval: DispatchTimeInterval) {
                switch timeInterval {
                case .seconds(let s):
                    self = .seconds(s)
                    
                case .milliseconds(let ms):
                    self = .milliseconds(ms)
                    
                case .microseconds(let us):
                    self = .microseconds(us)
                    
                case .nanoseconds(let ns):
                    self = .nanoseconds(ns)
                    
                case .never:
                    magnitude = .max
                    
                @unknown default:
                    fatalError()
                }
            }
            
            /// Creates a dispatch queue time interval from a floating-point seconds value.
            ///
            /// - Parameter value: The number of seconds, as a `Double`.
            public init(floatLiteral value: Double) {
                magnitude = Int(value * pow(10, 9))
            }
            
            /// Creates a dispatch queue time interval from an integer seconds value.
            ///
            /// - Parameter value: The number of seconds, as an `Int`.
            public init(integerLiteral value: Int) {
                let power = pow(Double(10), Double(9))
                magnitude = value * Int(power)
            }
            
            /// Creates a dispatch queue time interval from a binary integer type.
            ///
            /// If `exactly` cannot convert to an `Int`, the resulting time interval is `nil`.
            /// - Parameter exactly: A binary integer representing a time interval.
            public init?<T: BinaryInteger>(exactly source: T) {
                guard let value = Double(exactly: source) else { return nil }
                magnitude = Int(value * pow(10, 9))
            }
            
            private init(magnitude value: Int) {
                magnitude = value
            }
            
            public static func < (lhs: Stride, rhs: Stride) -> Bool {
                lhs.magnitude < rhs.magnitude
            }
            
            public static func * (lhs: Stride, rhs: Stride) -> Stride {
                Stride(magnitude: lhs.magnitude * rhs.magnitude)
            }
            
            public static func + (lhs: Stride, rhs: Stride) -> Stride {
                Stride(magnitude: lhs.magnitude + rhs.magnitude)
            }
            
            public static func - (lhs: Stride, rhs: Stride) -> Stride {
                Stride(magnitude: lhs.magnitude - rhs.magnitude)
            }
            
            public static func -= (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude -= rhs.magnitude
            }
            
            public static func *= (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude *= rhs.magnitude
            }
            
            public static func += (lhs: inout Stride, rhs: Stride) {
                lhs.magnitude += rhs.magnitude
            }
            
            public static func == (a: Stride, b: Stride) -> Bool {
                a.magnitude == b.magnitude
            }
            
            public static func seconds(_ s: Double) -> Stride {
                Stride(magnitude: Int(s * 1_000_000_000))
            }
            
            public static func seconds(_ s: Int) -> Stride {
                Stride(magnitude: snapProductToRange(s, 1_000_000_000))
            }
            public static func milliseconds(_ ms: Int) -> Stride {
                Stride(magnitude: snapProductToRange(ms, 1_000_000))
            }
            
            public static func microseconds(_ us: Int) -> Stride {
                Stride(magnitude: snapProductToRange(us, 1_000))
            }
            
            public static func nanoseconds(_ ns: Int) -> Stride {
                Stride(magnitude: ns)
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                magnitude = try container.decode(Int.self)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(magnitude)
            }
        }
    }
    
    /// Options that affect the operation of the dispatch queue scheduler.
    public struct PKSchedulerOptions {
        
        /// The dispatch queue quality of service.
        public var qos: DispatchQoS
        
        /// The dispatch queue work item flags.
        public var flags: DispatchWorkItemFlags
        
        /// The dispatch group, if any, that should be used for performing actions.
        public var group: DispatchGroup?
        
        public init(qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], group: DispatchGroup? = nil) {
            self.qos = qos
            self.flags = flags
            self.group = group
        }
    }
    
    public var minimumTolerance: PKSchedulerTimeType.Stride { .nanoseconds(0) }
    
    public var now: PKSchedulerTimeType { .init(.now()) }
    
    public func schedule(options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        
        let options = options ?? PKSchedulerOptions()
        
        async(group: options.group,
              qos: options.qos,
              flags: options.flags,
              execute: action)
    }
    
    public func schedule(after date: PKSchedulerTimeType, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) {
        
        let options = options ?? PKSchedulerOptions()
        
        asyncAfter(deadline: date.dispatchTime,
                   qos: options.qos,
                   flags: options.flags,
                   execute: action)
    }
    
    public func schedule(after date: PKSchedulerTimeType, interval: PKSchedulerTimeType.Stride, tolerance: PKSchedulerTimeType.Stride, options: PKSchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        
        let options = options ?? PKSchedulerOptions()
        
        let timer = DispatchSource.makeTimerSource(queue: self)
        
        timer.setEventHandler(qos: options.qos, flags: options.flags, handler: action)
        
        timer.schedule(deadline: date.dispatchTime, repeating: interval.timeInterval, leeway: tolerance.timeInterval)
        timer.resume()
        
        return AnyCancellable(cancel: timer.cancel)
    }
}



// This function is taken from swift-corlibs-libdispatch:
// https://github.com/apple/swift-corelibs-libdispatch/blob/c992dacf3ca114806e6ac9ffc9113b19255be9fe/src/swift/Time.swift#L134-L144
//
// Returns m1 * m2, clamped to the range [Int.min, Int.max].
// Because of the way this function is used, we can always assume
// that m2 > 0.
fileprivate func snapProductToRange(_ lhs: Int, _ rhs: Int) -> Int {
    assert(rhs > 0, "multiplier must be positive")
    let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
    if overflow {
        return lhs > 0 ? .max : .min
    }
    return result
}
