//
//  Logger.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 18/10/19.
//

import Foundation

final public class Logger {
    
    /// Allows Logs to be Printed in Debug Console.
    /// Default value is `true`
    public var isLoggingEnabled: Bool = true
    
    public static let `default` = Logger()
    
    /**
     Creates a `PKLogger`.
     */
    init() { }
    
    /**
     Writes the textual representations of the given items into the standard output.
     
     - parameter items: Zero or more items to print..
     - parameter separator: A string to print between each item. The default is a single space (" ").
     - parameter terminator: The string to print after all items have been printed. The default is a newline ("\n").
     
     */
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        guard isLoggingEnabled else { return }
        Swift.print(items, separator: separator, terminator: terminator)
        #endif
    }
    
    /**
     Writes the textual representations of the given items most suitable for debugging into the standard output.
     
     - parameter items: Zero or more items to print.
     - parameter separator: A string to print between each item. The default is a single space (" ").
     - parameter terminator: The string to print after all items have been printed. The default is a newline ("\n").
     
     */
    func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        guard isLoggingEnabled else { return }
        Swift.debugPrint(items, separator: separator, terminator: terminator)
        #endif
    }
    
    /**
     Handles APIRequest logging sent by the `PublisherKit`.
     
     - parameter request: URLRequest
     - parameter name: API name.
     */
    public func logAPIRequest(request: URLRequest, name: String) {
        #if DEBUG
        guard isLoggingEnabled else { return }
        
        Swift.print(
            """
            ------------------------------------------------------------
            API Call Request for:
            Name: \(name)
            \(request.debugDescription)
            
            """
        )
        #endif
    }
    
    /**
     Print JSON sent by the `PublisherKit`.
     
     - parameter data: JSON Data to be printed.
     */
    func printJSON(data: Data) {
        #if DEBUG
        guard isLoggingEnabled else { return }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            let newData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            
            Swift.print("""
                    ------------------------------------------------------------
                    JSON:
                           
                    """)
            Swift.print(String(data: newData, encoding: .utf8) ?? "nil")
            Swift.print("------------------------------------------------------------")
            
        } catch {
            
        }
        #endif
    }
    
    /**
     Print PropertyList sent by the `PublisherKit`.
     
     - parameter data: PropertyList Data to be printed.
     */
    func printPropertyList(data: Data) {
        #if DEBUG
        guard isLoggingEnabled else { return }
        
        do {
            let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            
            Swift.print("""
                    ------------------------------------------------------------
                    Property List:
                           
                    """)
            Swift.print(object)
            Swift.print("------------------------------------------------------------")
            
        } catch {
            
        }
        #endif
    }
    
    /**
     Handles errors sent by the `PublisherKit`.
     
     - parameter error: Error occurred.
     - parameter file: Source file name.
     - parameter line: Source line number.
     - parameter function: Source function name.
     */
    @inline(__always)
    func log(error: Error, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        #if DEBUG
        guard isLoggingEnabled else { return }
        
        Swift.print("⚠️ [PublisherKit: Error] \((String(describing: file) as NSString).lastPathComponent): line: \(line) : function: \(function)\n  ↪︎ \(error as NSError)\n")
        #endif
    }
    
    /**
     Handles assertions made throughout the `PublisherKit`.
     
     - parameter condition: Assertion condition.
     - parameter message: Assertion failure message.
     - parameter file: Source file name.
     - parameter line: Source line number.
     - parameter function: Source function name.
     */
    @inline(__always)
    func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        
        let condition = condition()
        
        if condition { return }
        
        let message = message()
        
        Swift.print("❗ [PublisherKit: Assertion Failure] in File: \((String(describing: file) as NSString).lastPathComponent): line: \(line) : function: \(function)\n  ↪︎ \(message)\n")
        Swift.assert(condition, message, file: file, line: line)
    }
    
    /**
     Handles preconditions made throughout the `PublisherKit`.
     
     - parameter condition: Precondition to be satisfied.
     - parameter message: Precondition failure message.
     - parameter file: Source file name.
     - parameter line: Source line number.
     - parameter function: Source function name.
     */
    @inline(__always)
    func precondition(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        
        let condition = condition()
        
        if condition { return }
        
        let message = message()
        
        Swift.print("❗ [PublisherKit: Precondition Failure] \((String(describing: file) as NSString).lastPathComponent): line: \(line) : function: \(function)\n  ↪︎ \(message)\n")
        Swift.preconditionFailure(message, file: file, line: line)
    }
    
    /**
     Handles fatal errors made throughout the `PublisherKit`.
     - Important: Implementers should guarantee that this function doesn't return, either by calling another `Never` function such as `fatalError()` or `abort()`, or by raising an exception.
     
     - parameter message: Fatal error message.
     - parameter file: Source file name.
     - parameter line: Source line number.
     - parameter function: Source function name.
     */
    @inline(__always)
    func fatalError(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) -> Never {
        
        let message = message()
        Swift.print("❗ [PublisherKit: Fatal Error] \((String(describing: file) as NSString).lastPathComponent): line: \(line) : function: \(function)\n  ↪︎ \(message)\n")
        Swift.fatalError(message, file: file, line: line)
    }
}
