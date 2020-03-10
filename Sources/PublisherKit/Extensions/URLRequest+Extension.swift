//
//  URLRequest+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

extension URLRequest {
    
    var debugDescription: String {
        
        let bodyString: String
        if let data = httpBody {
            bodyString = String(data: data, encoding: .utf8) ?? "nil"
        } else {
            bodyString = "nil"
        }
        
        return """
        ------------------------------------------------------------
        Request Method: \(httpMethod ?? "nil")
        Request URL: \(url?.absoluteString ?? "nil")
        
        Request Parameters: \((url?.parameters ?? [:]).prettyPrint)
        
        Request Headers: \((allHTTPHeaderFields ?? [:]).prettyPrint)
        
        Request HTTPBody: \(bodyString)
        ------------------------------------------------------------
        """
    }
}
