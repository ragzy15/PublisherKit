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
     Handles APIRequest logging sent by the `PublisherKit`.
     
     - parameter request: URLRequest
     - parameter name: API name.
     */
    func logAPIRequest(request: URLRequest, name: String) {
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
}
