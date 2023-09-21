//
//  CurrentValueValidation.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 20.09.2023.
//

import UIKit

struct CurrentValueValidation {
    static let pending = CurrentValueValidation(result: .pending, message: nil)
    
    static func valid(_ message: String = "Valid") -> CurrentValueValidation {
        CurrentValueValidation(result: .valid, message: message)
    }
    
    static func invalid(_ message: String = "Invalid") -> CurrentValueValidation {
        CurrentValueValidation(result: .invalid, message: message)
    }
    
    enum Result {
        case valid,
             invalid,
             pending
    }
    
    let result: Result
    let message: String?
    
    var isInvalid: Bool {
        result == .invalid
    }
    
    var color: UIColor {
        switch result {
        case .valid:
            return .systemGreen
        case .invalid:
            return .systemRed
        case .pending:
            return .tintColor
        }
    }
}
