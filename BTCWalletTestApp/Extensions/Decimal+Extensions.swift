//
//  Decimal+Extensions.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import Foundation

extension Decimal {
    static let bitcoinRate: Decimal = pow(10, 8)
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 8
        formatter.maximumFractionDigits = 8
        return formatter.string(from: self as NSDecimalNumber)!
    }
}
