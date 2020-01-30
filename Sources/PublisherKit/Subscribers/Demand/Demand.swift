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
    public struct Demand: Equatable, Comparable, Hashable, Codable, CustomStringConvertible {
        
        /// Requests as many values as the `PKPublisher` can produce.
        public static let unlimited: Demand = .init(Int.max, isUnlimited: true)
        
        /// A demand for no items.
        ///
        /// This is equivalent to `Demand.max(0)`.
        public static let none: Demand = .max(0)
        
        /// Limits the maximum number of values.
        /// The `PKPublisher` may send fewer than the requested number.
        /// Negative values will result in a `fatalError`.
        @inlinable public static func max(_ value: Int) -> Demand {
            if value < 0 { fatalError("Maximum demand value cannot be less than 0") }
            return .init(value)
        }
        
        /// Returns the number of requested values, or nil if unlimited.
        @inlinable public var max: Int? { value == Demand.unlimited ? nil : value }
        
        @usableFromInline var value: Int
        
        private let isUnlimited: Bool
        
        @usableFromInline init(_ value: Int, isUnlimited: Bool = false) {
            self.value = value
            self.isUnlimited = isUnlimited
        }
        
        /// When adding any value to .unlimited, the result is .unlimited.
        @inlinable public static func + (lhs: Demand, rhs: Demand) -> Demand {
            if lhs == .unlimited || rhs == .unlimited {
                return .unlimited
            }
            
            return .max(lhs.value + rhs.value)
        }
        
        /// When adding any value to .unlimited, the result is .unlimited.
        @inlinable public static func += (lhs: inout Demand, rhs: Demand) {
            if lhs == .unlimited || rhs == .unlimited {
                lhs = .unlimited
                return
            }
            
            return lhs.value += rhs.value
        }
        
        /// When adding any value to .unlimited, the result is .unlimited.
        @inlinable public static func + (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return .unlimited
            }
            
            return .max(lhs.value + rhs)
        }
        
        /// When adding any value to .unlimited, the result is .unlimited.
        @inlinable public static func += (lhs: inout Demand, rhs: Int) {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return
            }
            
            lhs.value += rhs
        }
        
        /// When multiplying any value to .unlimited, the result is .unlimited.
        public static func * (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return .unlimited
            }
            
            return .max(lhs.value * rhs)
        }
        
        /// When multiplying any value to .unlimited, the result is .unlimited.
        @inlinable public static func *= (lhs: inout Demand, rhs: Int) {
            if lhs == .unlimited {
                return
            } else if rhs == Demand.unlimited.value {
                lhs = .unlimited
            }
            
            return lhs.value *= rhs
        }
        
        /// When subtracting any value (including .unlimited) from .unlimited, the result is still .unlimited. Subtracting unlimited from any value (except unlimited) results in .max(0). A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        @inlinable public static func - (lhs: Demand, rhs: Demand) -> Demand {
            if lhs == .unlimited {
                return .unlimited
            } else if lhs == .unlimited && rhs == .unlimited {
                return .unlimited
            } else if (lhs != .unlimited && rhs == .unlimited) || (lhs.value - rhs.value <= 0) {
                return .max(0)
            } else {
                return .max(lhs.value - rhs.value)
            }
        }
        
        /// When subtracting any value (including .unlimited) from .unlimited, the result is still .unlimited. Subtracting unlimited from any value (except unlimited) results in .max(0). A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        @inlinable public static func -= (lhs: inout Demand, rhs: Demand) {
            if lhs == .unlimited {
                return
            } else if lhs == .unlimited && rhs == .unlimited {
                lhs = .unlimited
            } else if (lhs != .unlimited && rhs == .unlimited) || (lhs.value - rhs.value <= 0) {
                lhs = .max(0)
            } else {
                lhs.value -= rhs.value
            }
        }
        
        /// When subtracting any value from .unlimited, the result is still .unlimited. A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        @inlinable public static func - (lhs: Demand, rhs: Int) -> Demand {
            if lhs == .unlimited {
                return .unlimited
            } else if lhs == .unlimited && rhs == Demand.unlimited.value {
                return .unlimited
            } else if (lhs != .unlimited && rhs == Demand.unlimited.value) || (lhs.value - rhs <= 0) {
                return .max(0)
            } else {
                return .max(lhs.value - rhs)
            }
        }
        
        /// When subtracting any value from .unlimited, the result is still .unlimited. A negative demand is not possible; any operation that would result in a negative value is clamped to .max(0).
        @inlinable public static func -= (lhs: inout Demand, rhs: Int) {
            if lhs == .unlimited {
                return
            } else if lhs == .unlimited && rhs == Demand.unlimited.value {
                return
            } else if (lhs != .unlimited && rhs == Demand.unlimited.value) || (lhs.value - rhs <= 0) {
                lhs = .max(0)
            } else {
                lhs.value -= rhs
            }
        }
        
        /// If lhs is .unlimited, then the result is always true. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return true
            }
            
            return lhs.value > rhs
        }
        
        /// If lhs is .unlimited, then the result is always true. Otherwise, the two max values are compared.
        @inlinable public static func >= (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return true
            }
            
            return lhs.value >= rhs
        }
        
        /// If rhs is .unlimited, then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || rhs == Demand.unlimited.value {
                return false
            }
            
            return lhs > rhs.value
        }
        
        /// If rhs is .unlimited, then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func >= (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || rhs == Demand.unlimited.value {
                return false
            }
            
            return lhs >= rhs.value
        }
        
        /// If lhs is .unlimited, then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return false
            }
            
            return lhs.value < rhs
        }
        
        /// If rhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || rhs == Demand.unlimited.value {
                return true
            }
            
            return lhs < rhs.value
        }
        
        /// If lhs is .unlimited, then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func <= (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return false
            }
            
            return lhs.value <= rhs
        }
        
        /// If rhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func <= (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || rhs == Demand.unlimited.value {
                return true
            }
            
            return lhs <= rhs.value
        }
        
        /// If lhs is .unlimited, then the result is always false. If rhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func < (lhs: Demand, rhs: Demand) -> Bool {
            if lhs == .unlimited || rhs == .unlimited {
                return false
            }
            
            return lhs.value < rhs.value
        }
        
        /// If lhs is .unlimited and rhs is .unlimited then the result is true. Otherwise, the rules for `<=` are followed.
        @inlinable public static func <= (lhs: Demand, rhs: Demand) -> Bool {
            if lhs == .unlimited && rhs == .unlimited {
                return true
            } else if lhs != .unlimited && rhs == .unlimited {
                return true
            } else if lhs == .unlimited && rhs != .unlimited {
                return false
            }
            
            return lhs.value <= rhs.value
        }
        
        /// If lhs is .unlimited and rhs is .unlimited then the result is true. Otherwise, the rules for `>=` are followed.
        @inlinable public static func >= (lhs: Demand, rhs: Demand) -> Bool {
            if lhs == .unlimited && rhs == .unlimited {
                return true
            } else if lhs == .unlimited && rhs != .unlimited {
                return true
            } else if lhs != .unlimited && rhs == .unlimited {
                return false
            }
            
            return lhs.value >= rhs.value
        }
        
        /// If rhs is .unlimited, then the result is always false. If lhs is .unlimited then the result is always false. Otherwise, the two max values are compared.
        @inlinable public static func > (lhs: Demand, rhs: Demand) -> Bool {
            if lhs == .unlimited || rhs == .unlimited {
                return false
            }
            
            return lhs.value > rhs.value
        }
        
        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        @inlinable public static func == (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return false
            }
            
            return lhs.value == rhs
        }
        
        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        @inlinable public static func != (lhs: Demand, rhs: Int) -> Bool {
            if lhs == .unlimited || rhs == Demand.unlimited.value {
                return true
            }
            
            return lhs.value != rhs
        }
        
        /// Returns `true` if `lhs` and `rhs` are equal. `.unlimited` is not equal to any integer.
        @inlinable public static func == (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || lhs == Demand.unlimited.value {
                return false
            }
            
            return lhs == rhs.value
        }
        
        /// Returns `true` if `lhs` and `rhs` are not equal. `.unlimited` is not equal to any integer.
        @inlinable public static func != (lhs: Int, rhs: Demand) -> Bool {
            if rhs == .unlimited || lhs == Demand.unlimited.value {
                return true
            }
            
            return lhs != rhs.value
        }
        
        public static func == (lhs: Demand, rhs: Demand) -> Bool {
            if lhs.isUnlimited && rhs.isUnlimited {
                return true
            } else if lhs.isUnlimited || rhs.isUnlimited {
                return false
            }
            
            return lhs.value == rhs.value
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
        
        public var description: String {
            if self == .unlimited {
                return "unlimited"
            } else {
                return "max(\(value))"
            }
        }
    }
}
