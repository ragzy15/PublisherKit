//
//  Immediate Scheduler.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 14/03/20.
//

/// A scheduler for performing synchronous actions.
///
/// You can use this scheduler for immediate actions. If you attempt to schedule actions after a specific date, the scheduler ignores the date and executes synchronously.
public struct ImmediateScheduler: Scheduler {
    
    /// The time type used by the immediate scheduler.
    public struct SchedulerTimeType: Strideable {
        
        /// Returns the distance to another immediate scheduler time; this distance is always `0` in the context of an immediate scheduler.
        ///
        /// - Parameter other: The other scheduler time.
        /// - Returns: `0`, as a `Stride`.
        public func distance(to other: SchedulerTimeType) -> Stride {
            .zero
        }
        
        /// Advances the time by the specified amount; this is meaningless in the context of an immediate scheduler.
        ///
        /// - Parameter n: The amount to advance by. The `ImmediateScheduler` ignores this value.
        /// - Returns: An empty `SchedulerTimeType`.
        public func advanced(by n: Stride) -> SchedulerTimeType {
            SchedulerTimeType()
        }
        
        /// The increment by which the immediate scheduler counts time.
        public struct Stride: ExpressibleByFloatLiteral, Comparable, SignedNumeric, Codable, PKSchedulerTimeIntervalConvertible {
            
            public typealias FloatLiteralType = Double
            
            public typealias IntegerLiteralType = Int
            
            public typealias Magnitude = Int
            
            public var magnitude: Int
            
            public init(_ value: Int) {
                magnitude = value
            }
            
            public init(integerLiteral value: Int) {
                magnitude = value
            }
            
            public init(floatLiteral value: Double) {
                magnitude = Int(value)
            }
            
            public init?<T: BinaryInteger>(exactly source: T) {
                guard let value = Int(exactly: source) else { return nil }
                magnitude = value
            }
            
            public static func < (lhs: Stride, rhs: Stride) -> Bool {
                lhs.magnitude < rhs.magnitude
            }
            
            public static func * (lhs: Stride, rhs: Stride) -> Stride {
                return Stride(lhs.magnitude * rhs.magnitude)
            }
            
            public static func + (lhs: Stride, rhs: Stride) -> Stride {
                return Stride(lhs.magnitude + rhs.magnitude)
            }
            
            public static func - (lhs: Stride, rhs: Stride) -> Stride {
                return Stride(lhs.magnitude - rhs.magnitude)
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
            
            public static func seconds(_ s: Int) -> Stride { .zero }
            
            public static func seconds(_ s: Double) -> Stride { .zero }
            
            public static func milliseconds(_ ms: Int) -> Stride { .zero }
            
            public static func microseconds(_ us: Int) -> Stride { .zero }
            
            public static func nanoseconds(_ ns: Int) -> Stride { .zero }
            
            public static func == (a: Stride, b: Stride) -> Bool {
                a.magnitude == b.magnitude
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
    
    public typealias SchedulerOptions = Never
    
    /// The shared instance of the immediate scheduler.
    ///
    /// You cannot create instances of the immediate scheduler yourself. Use only the shared instance.
    public static let shared: ImmediateScheduler = .init()
    
    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        action()
    }
    
    public var now: SchedulerTimeType { .init() }
    
    public var minimumTolerance: SchedulerTimeType.Stride { .zero }
    
    public func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        action()
    }
    
    public func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        action()
        return Subscriptions.empty
    }
}
