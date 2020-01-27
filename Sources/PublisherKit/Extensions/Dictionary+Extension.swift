//
//  Dictionary+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

extension Dictionary {
    
    var prettyPrint: String {
        let prefix = isEmpty ? "" : "\n"
        var printString = "\(prefix)["
        
        for (key, value) in self {
            let itemString = "\n\t\(key): \(value),"
            printString.append(itemString)
        }
        
        let postfix = isEmpty ? " " : "\n"
        printString.append("\(postfix)]")
        
        return printString
    }
}

extension Dictionary where Value: OptionalDelegate {
    
    var prettyPrint: String {
        let prefix = isEmpty ? "" : "\n"
        var printString = "\(prefix)["
        
        for (key, value) in self {
            let optionalValue = value.unwrappedValue()
            let value = optionalValue == nil ? "nil" : "\(optionalValue!)"
            
            let itemString = "\n\t\(key): \(value),"
            printString.append(itemString)
        }
        
        let postfix = isEmpty ? " " : "\n"
        printString.append("\(postfix)]")
        
        return printString
    }
}
