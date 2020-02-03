//
//  Demand.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 19/12/19.
//

import Foundation

extension PKSubscribers {
    
    /// A requested number of items, sent to a publisher from a subscriber via the subscription.
    ///
    /// - `unlimited`: A request for an unlimited number of items.
    /// - `max`: A request for a maximum number of items.
    public struct Demand: Equatable, Comparable, Hashable, Codable, CustomStringConvertible {
        
        @usableFromInline let rawValue: UInt
        
        @usableFromInline init(rawValue: UInt) {
            self.rawValue = min(UInt(Int.max) + 1, rawValue)
        }
        
        /// Requests as many values as the `Publisher` can produce.
        public static let unlimited = Demand(rawValue: .max)
        
        /// A demand for no items.
        ///
        /// This is equivalent to `Demand.max(0)`.
        public static let none: Demand = .max(0)
        
        /// Limits the maximum number of values.
        /// The `Publisher` may send fewer than the requested number.
        /// Negative values will result in a `fatalError`.
        @inlinable public static func max(_ value: Int) -> Demand {
            precondition(value >= 0, "Maximum demand value cannot be less than 0")
            return Demand(rawValue: UInt(value))
        }
        
        public var description: String {
            self == .unlimited ? "unlimited" : "max(\(rawValue))"
        }
        
        /// When adding any value to `.unlimited`, the result is `.unlimited`.
        @inlinable public static func + (lhs: Demand, rhs: Demand) -> Demand {
            switch (lhs, rhs) {
            case (.unlimited, _):
                return .unlimited
                
            case (_, .unlimited):
                return .unlimited
                
            default:
                let (sum, isOverflow) = Int(lhs.rawValue)
                    .addingReportingOverflow(Int(rhs.rawValue))
                return isOverflow ? .unlimited : .max(sum)
            }
        }
        
        /// When adding any value to `.unlimited`, the result is `.unlimited`.
        @inlinable public static func += (lhs: inout Demand, rhs: Demand) {
            if lhs == .unlimited { return }
            lhs = lhs + rhs
        }
        
        /// When adding any value to` .unlimited`, the result is `.unlimited`.
        @inlinable public static func + (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited { return .unlimited }
            
            let (sum, isOverflow) = Int(lhs.rawValue).addingReportingOverflow(rhs)
            return isOverflow ? .unlimited : .max(sum)
        }
        
        /// When adding any value to `.unlimited`, the result is `.unlimited`.
        @inlinable public static func += (lhs: inout Demand, rhs: Int) {
            lhs = lhs + rhs
        }
        
        /// When multiplying any value to `.unlimited`, the result is `.unlimited`.
        public static func * (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited { return .unlimited }
            
            let (product, isOverflow) = Int(lhs.rawValue)
                .multipliedReportingOverflow(by: rhs)
            return isOverflow ? .unlimited : .max(product)
        }
        
        /// When multiplying any value to `.unlimited`, the result is `.unlimited`.
        @inlinable public static func *= (lhs: inout Demand, rhs: Int) {
            lhs = lhs * rhs
        }
        
        /// When subtracting any value (including `.unlimited`) from `.unlimited`, the result is still `.unlimited`. Subtracting `.unlimited` from any value (except `.unlimited`) results in `.max(0)`.
        /// A negative demand is not possible; any operation that would result in a negative value is clamped to `.max(0)`.
        @inlinable public static func - (lhs: Demand, rhs: Demand) -> Demand {
            switch (lhs, rhs) {
            case (.unlimited, _):
                return .unlimited
                
            case (_, .unlimited):
                return .none
                
            default:
                let (difference, isOverflow) = Int(lhs.rawValue)
                    .subtractingReportingOverflow(Int(rhs.rawValue))
                return isOverflow || difference < 0 ? .none : .max(difference)
            }
        }
        
        /// When subtracting any value (including `.unlimited`) from `.unlimited`, the result is still `.unlimited`. Subtracting unlimited from any value (except `.unlimited`) results in `.max(0)`.
        /// A negative demand is not possible; any operation that would result in a negative value is clamped to `.max(0)`.
        @inlinable public static func -= (lhs: inout Demand, rhs: Demand) {
            lhs = lhs - rhs
        }
        
        /// When subtracting any value from `.unlimited`, the result is still `.unlimited`.
        /// A negative demand is not possible; any operation that would result in a negative value is clamped to `.max(0)`
        @inlinable public static func - (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited { return .unlimited }
            
            let (difference, isOverflow) = Int(lhs.rawValue)
                .subtractingReportingOverflow(rhs)
            return isOverflow || difference < 0 ? .none : .max(difference)
        }
        
        /// When subtracting any value from `.unlimited,` the result is still `.unlimited`.
        /// A negative demand is not possible; any operation that would result in a negative value is clamped to `.max(0)`
        @inlinable public static func -= (lhs: inout Demand, rhs: Int) {
            if lhs == .unlimited { return }
            lhs = lhs - rhs
        }
        
        /// If lhs is `.unlimited`, then the result is always `true`. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? true : Int(lhs.rawValue) > rhs
        }
        
        /// If lhs is `.unlimited`, then the result is always `true`. Otherwise, the two max values are compared.
        @inlinable public static func >= (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? true : Int(lhs.rawValue) >= rhs
        }
        
        /// If rhs is `.unlimited`, then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? false : lhs >  Int(rhs.rawValue)
        }
        
        /// If rhs is `.unlimited`, then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func >= (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? false : lhs >= Int(rhs.rawValue)
        }
        
        /// If lhs is `.unlimited`, then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? false : Int(lhs.rawValue) < rhs
        }
        
        /// If rhs is `.unlimited` then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? true : lhs < Int(rhs.rawValue)
        }
        
        /// If lhs is `.unlimited`, then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func <= (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? false : Int(lhs.rawValue) <= rhs
        }
        
        /// If rhs is `.unlimited` then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func <= (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? true : lhs <= Int(rhs.rawValue)
        }
        
        /// If lhs is `.unlimited`, then the result is always `false`. If rhs is `.unlimited` then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Demand, rhs: Demand) -> Bool {
            switch (lhs, rhs) {
            case (.unlimited, _):
                return false
                
            case (_, .unlimited):
                return true
                
            default:
                return lhs.rawValue < rhs.rawValue
            }
        }
        
        /// If lhs is `.unlimited` and rhs is `.unlimited` then the result is `true`. Otherwise, the rules for `<=` are followed.
        @inlinable public static func <= (lhs: Demand, rhs: Demand) -> Bool {
            switch (lhs, rhs) {
            case (.unlimited, .unlimited):
                return true
                
            case (.unlimited, _):
                return false
                
            case (_, .unlimited):
                return true
                
            default:
                return lhs.rawValue <= rhs.rawValue
            }
        }
        
        /// If lhs is `.unlimited` and rhs is `.unlimited` then the result is `true`. Otherwise, the rules for `>=` are followed.
        @inlinable public static func >= (lhs: Demand, rhs: Demand) -> Bool {
            switch (lhs, rhs) {
            case (.unlimited, .unlimited):
                return true
                
            case (.unlimited, _):
                return true
                
            case (_, .unlimited):
                return false
                
            default:
                return lhs.rawValue >= rhs.rawValue
            }
        }
        
        /// If rhs is `.unlimited`, then the result is always `false`. If lhs is `.unlimited` then the result is always `false`. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Demand, rhs: Demand) -> Bool {
            switch (lhs, rhs) {
            case (.unlimited, .unlimited):
                return false
                
            case (.unlimited, _):
                return true
                
            case (_, .unlimited):
                return false
                
            default:
                return lhs.rawValue > rhs.rawValue
            }
        }
        
        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        @inlinable public static func == (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? false : Int(lhs.rawValue) == lhs
        }
        
        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        @inlinable public static func != (lhs: Demand, rhs: Int) -> Bool {
            lhs == .unlimited ? true : Int(lhs.rawValue) != lhs
        }
        
        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        @inlinable public static func == (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? false : Int(rhs.rawValue) == lhs
        }
        
        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        @inlinable public static func != (lhs: Int, rhs: Demand) -> Bool {
            rhs == .unlimited ? true : Int(rhs.rawValue) != lhs
        }
        
        @inlinable public static func == (lhs: Demand, rhs: Demand) -> Bool {
            lhs.rawValue == rhs.rawValue
        }
        
        /// Returns the number of requested values, or `nil` if `.unlimited`.
        @inlinable public var max: Int? { self == .unlimited ? nil : Int(self.rawValue) }
        
        public init(from decoder: Decoder) throws {
            try self.init(rawValue: decoder.singleValueContainer().decode(UInt.self))
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
}
