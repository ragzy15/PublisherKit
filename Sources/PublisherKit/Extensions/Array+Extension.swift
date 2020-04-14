//
//  Array+Extension.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 15/10/19.
//

extension Array {
    
    var tuple: Any? {
        switch count {
        case 0:
            return ()
        case 1:
            return (self[0])
        case 2:
            return (self[0], self[1])
        case 3:
            return (self[0], self[1], self[2])
        case 4:
            return (self[0], self[1], self[2], self[3])
        case 5:
            return (self[0], self[1], self[2], self[3], self[4])
        case 6:
            return (self[0], self[1], self[2], self[3], self[4], self[5])
        case 7:
            return (self[0], self[1], self[2], self[3], self[4], self[5], self[6])
        default:
            return nil
        }
    }
}
