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
    /// - unlimited: A request for an unlimited number of items.
    /// - max: A request for a maximum number of items.
    public struct Demand: Equatable, Comparable, Hashable, Codable {
        
        /// Requests as many values as the `PKPublisher` can produce.
        public static let unlimited: PKSubscribers.Demand = .init(Int.max)

        /// A demand for no items.
        ///
        /// This is equivalent to `Demand.max(0)`.
        public static let none: PKSubscribers.Demand = .max(0)

        /// Limits the maximum number of values.
        /// The `PKPublisher` may send fewer than the requested number.
        /// Negative values will result in a `fatalError`.
        public static func max(_ value: Int) -> PKSubscribers.Demand {
            if value < 0 { fatalError("Maximum demand value cannot be less than 0") }
            return .init(value)
        }
        
        private var value: Int
        
        private init(_ value: Int) {
            self.value = value
        }

        /// When adding any value to .unlimited, the result is .unlimited.
        public static func + (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> PKSubscribers.Demand {
            .init(lhs.value + rhs.value)
        }

        /// When adding any value to .unlimited, the result is .unlimited.
        public static func += (lhs: inout PKSubscribers.Demand, rhs: PKSubscribers.Demand) {
            lhs.value += rhs.value
        }

        /// When adding any value to .unlimited, the result is .unlimited.
        public static func + (lhs: PKSubscribers.Demand, rhs: Int) -> PKSubscribers.Demand {
            .init(lhs.value + rhs)
        }

        /// When adding any value to .unlimited, the result is .unlimited.
        public static func += (lhs: inout PKSubscribers.Demand, rhs: Int) {
            lhs.value += rhs
        }

        public static func * (lhs: PKSubscribers.Demand, rhs: Int) -> PKSubscribers.Demand {
            .init(lhs.value * rhs)
        }

        public static func *= (lhs: inout PKSubscribers.Demand, rhs: Int) {
            lhs.value *= rhs
        }

        /// When subtracting any value (including .unlimited) from .unlimited, the result is still .unlimited. Subtracting unlimited from any value (except unlimited) results in .max(0). A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        public static func - (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> PKSubscribers.Demand {
            .init(lhs.value - rhs.value)
        }

        /// When subtracting any value (including .unlimited) from .unlimited, the result is still .unlimited. Subtracting unlimited from any value (except unlimited) results in .max(0). A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        public static func -= (lhs: inout PKSubscribers.Demand, rhs: PKSubscribers.Demand) {
            lhs.value -= rhs.value
        }

        /// When subtracting any value from .unlimited, the result is still .unlimited. A negative demand is possible, but be aware that it is not usable when requesting values in a subscription.
        public static func - (lhs: PKSubscribers.Demand, rhs: Int) -> PKSubscribers.Demand {
            .init(lhs.value * rhs)
        }

        /// When subtracting any value from .unlimited, the result is still .unlimited. A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0)
        public static func -= (lhs: inout PKSubscribers.Demand, rhs: Int) {
            lhs.value -= rhs
        }

        public static func > (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value > rhs
        }

        public static func >= (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value >= rhs
        }

        public static func > (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs > rhs.value
        }

        public static func >= (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs >= rhs.value
        }

        public static func < (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value < rhs
        }

        public static func < (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs < rhs.value
        }

        public static func <= (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value <= rhs
        }

        public static func <= (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs <= rhs.value
        }

        /// If lhs is .unlimited, then the result is always false. If rhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        public static func < (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> Bool {
            lhs.value < rhs.value
        }

        /// If lhs is .unlimited and rhs is .unlimited then the result is true. Otherwise, the rules for < are followed.
        public static func <= (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> Bool {
            lhs.value <= rhs.value
        }

        /// Returns a Boolean value that indicates whether the value of the first
        /// argument is greater than or equal to that of the second argument.
        ///
        /// - Parameters:
        ///   - lhs: A value to compare.
        ///   - rhs: Another value to compare.
        public static func >= (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> Bool {
            lhs.value >= rhs.value
        }

        /// If rhs is .unlimited, then the result is always false. If lhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        public static func > (lhs: PKSubscribers.Demand, rhs: PKSubscribers.Demand) -> Bool {
            lhs.value > rhs.value
        }

        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        public static func == (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value == rhs
        }

        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        public static func != (lhs: PKSubscribers.Demand, rhs: Int) -> Bool {
            lhs.value != rhs
        }

        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        public static func == (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs == rhs.value
        }

        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        public static func != (lhs: Int, rhs: PKSubscribers.Demand) -> Bool {
            lhs != rhs.value
        }
        /// Returns the number of requested values, or nil if unlimited.
        public var max: Int? { value == Demand.unlimited ? nil : value }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
}
