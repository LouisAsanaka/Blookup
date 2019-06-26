//
//  ISBN.swift
//  Blookup
//
//  Created by Louis on 2019/6/15.
//  Copyright © 2019 Louis. All rights reserved.
//

import Foundation

struct ISBN: CustomStringConvertible {
    
    enum Format: String {
        case ISBN10 = "ISBN-10"
        case ISBN13 = "ISBN-13"
        case INVALID
    }
    
    var description: String {
        return isbnString
    }
    
    let isbnString: String
    let format: Format
    
    init(_ isbn: String) {
        self.isbnString = isbn
        switch isbn.count {
        case 10:
            self.format = .ISBN10
        case 13:
            self.format = .ISBN13
        default:
            self.format = .INVALID
        }
    }
    
    // Validate an ISBN-13
    func validate() -> Bool {
        if self.format != .ISBN13 {
            return false
        }
        let weight = [1, 3]
        var checksum = 0
        
        for i in 0..<12 {
            if let intCharacter = Int(String(isbnString[isbnString.index(isbnString.startIndex, offsetBy: i)])) {
                checksum += weight[i % 2] * intCharacter
            }
        }
        if let checkDigit = Int(String(isbnString[isbnString.index(isbnString.startIndex, offsetBy: 12)])) {
            return (checkDigit - ((10 - (checksum % 10)) % 10) == 0)
        }
        return false
    }
    
    // Convert an ISBN-13 to an ISBN-10
    func convert() -> String {
        if self.format == .ISBN10 {
            return isbnString
        } else if self.format == .INVALID {
            return ""
        }
        let range = isbnString.index(isbnString.startIndex, offsetBy: 3) ..< isbnString.index(isbnString.endIndex, offsetBy: -1)
        let shortISBN = isbnString[range]
        
        var weights = [Int]()
        weights += 2...10
        weights = weights.reversed()
        
        var sum = 0
        for i in 0..<shortISBN.count {
            if let intCharacter = Int(String(shortISBN[shortISBN.index(shortISBN.startIndex, offsetBy: i)])) {
                sum += weights[i] * intCharacter
            }
        }
        let checksum = (11 - (sum % 11)) % 11
        return shortISBN + String(checksum)
    }
}
