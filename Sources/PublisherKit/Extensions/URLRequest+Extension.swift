//
//  URLRequest+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//  Copyright © 2019 Raghav Ahuja. All rights reserved.
//

import Foundation

extension URLRequest {
    
    var debugDescription: String {
        """
        ------------------------------------------------------------
        Request Method: \(httpMethod ?? "nil")
        Request URL: \(url?.absoluteString ?? "nil")
        
        Request Parameters: \((url?.parameters ?? [:]).prettyPrint)
        
        Request Headers: \((allHTTPHeaderFields ?? [:]).prettyPrint)
        
        Request HTTPBody: \(httpBody?.debugDescription ?? "nil")
        ------------------------------------------------------------
        """
    }
}
