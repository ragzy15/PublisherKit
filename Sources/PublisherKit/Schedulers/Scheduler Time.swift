//
//  SchedulerTime.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 25/12/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

public struct SchedulerTime: Comparable, SignedNumeric, ExpressibleByFloatLiteral, Hashable, Codable {
    
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
            let power = pow(Double(10), Double(9))
            magnitude = s * Int(power)
            
        case .milliseconds(let ms):
            let power = pow(Double(10), Double(6))
            magnitude = ms * Int(power)
            
        case .microseconds(let us):
            let power = pow(Double(10), Double(3))
            magnitude = us * Int(power)
            
        case .nanoseconds(let ns):
            magnitude = ns
            
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
    public init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = Double(exactly: source) else { return nil }
        magnitude = Int(value * pow(10, 9))
    }
        
    private init(magintude value: Int) {
        magnitude = value
    }
    
    
    /// Converts the specified number of seconds into an instance of this scheduler time type.
    public static func seconds(_ s: Double) -> SchedulerTime {
        .init(floatLiteral: s)
    }
    
    /// Converts the specified number of seconds, as a floating-point value, into an instance of this scheduler time type.
    public static func seconds(_ s: Int) -> SchedulerTime {
        .init(.seconds(s))
    }
    
    /// Converts the specified number of milliseconds into an instance of this scheduler time type.
    public static func milliseconds(_ ms: Int) -> SchedulerTime {
        .init(.milliseconds(ms))
    }
    
    /// Converts the specified number of microseconds into an instance of this scheduler time type.
    public static func microseconds(_ us: Int) -> SchedulerTime {
        .init(.microseconds(us))
    }
    
    /// Converts the specified number of nanoseconds into an instance of this scheduler time type.
    public static func nanoseconds(_ ns: Int) -> SchedulerTime {
        .init(.nanoseconds(ns))
    }
    
    public static func < (lhs: SchedulerTime, rhs: SchedulerTime) -> Bool {
        lhs.magnitude < rhs.magnitude
    }
    
    public static func * (lhs: SchedulerTime, rhs: SchedulerTime) -> SchedulerTime {
        .init(magintude: lhs.magnitude * rhs.magnitude)
    }
    
    public static func + (lhs: SchedulerTime, rhs: SchedulerTime) -> SchedulerTime {
        .init(magintude: lhs.magnitude + rhs.magnitude)
    }
    
    public static func - (lhs: SchedulerTime, rhs: SchedulerTime) -> SchedulerTime {
        .init(magintude: lhs.magnitude - rhs.magnitude)
    }
    
    public static func -= (lhs: inout SchedulerTime, rhs: SchedulerTime) {
        lhs.magnitude -= rhs.magnitude
    }
    
    public static func *= (lhs: inout SchedulerTime, rhs: SchedulerTime) {
        lhs.magnitude *= rhs.magnitude
    }
    
    public static func += (lhs: inout SchedulerTime, rhs: SchedulerTime) {
        lhs.magnitude += rhs.magnitude
    }
    
    public static func == (a: SchedulerTime, b: SchedulerTime) -> Bool {
        a.magnitude == b.magnitude
    }
}
