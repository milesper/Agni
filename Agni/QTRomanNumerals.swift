//
//  QTRomanNumerals.swift
//  QTRomanNumeralExample
//
//  Created by Michael Ginn on 7/17/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class QTRomanNumerals: NSObject {
    static let conversions = [
        1: "I",
        4: "IV",
        5: "V",
        9: "IX",
        10: "X",
        40: "XL",
        50: "L",
        90: "XC",
        100: "C",
        400: "CD",
        500: "D",
        900: "CM",
        1000: "M"
    ]
    static let numbers = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
    
    class func convertToRomanNum(var decimalNum:Int)->String{
        var finalString = "" //will use to build Roman num string
        while decimalNum > 0{
            for number in numbers{
                if decimalNum >= number{
                    decimalNum = decimalNum - number
                    finalString += conversions[number]!
                    break
                }
            }
        }
        return finalString
    }
}
