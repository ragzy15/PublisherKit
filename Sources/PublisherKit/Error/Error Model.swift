//
//  ErrorModel.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

import Foundation

// MARK: - ErrorModel
public struct ErrorModel: Codable {
    
    public let businessCode: Int?
    public let errorCode: Int?
    public let message: String?
    public let status: String?
    
    public var code: Int? {
        return businessCode ?? errorCode
    }
    
    public init(businessCode: Int?, errorCode: Int?, message: String?, status: String?) {
        self.businessCode = businessCode
        self.errorCode = errorCode
        self.message = message
        self.status = status
    }
    
    public enum CodingKeys: String, CodingKey {
        case businessCode = "business_error_code"
        case errorCode = "error_code"
        case message
        case status
    }
}
