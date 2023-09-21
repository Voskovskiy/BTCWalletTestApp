//
//  UserDefaults+Extensions.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 14.09.2023.
//

import Foundation

extension UserDefaults {
    private enum AppKeys: String {
        case mnemonicPhrase = "MNEMONIC_PHRASE"
        case loggedIn = "LOGGED_IN"
        case lastTransaction = "LAST_TRANSACTION"
    }
    
    var storedMnemonicPhrase: String? {
        get { value(forKey: AppKeys.mnemonicPhrase.rawValue) as? String }
        set { set(newValue, forKey: AppKeys.mnemonicPhrase.rawValue) }
    }
    
    var loggedIn: Bool {
        get { value(forKey: AppKeys.loggedIn.rawValue) as? Bool ?? false }
        set { set(newValue, forKey: AppKeys.loggedIn.rawValue) }
    }
    
    var lastTransaction: LastTransaction? {
        get {
            if let storedObj = object(forKey: AppKeys.lastTransaction.rawValue) as? Data,
               let lastTransaction = try? JSONDecoder().decode(LastTransaction.self,
                                                               from: storedObj) {
                return lastTransaction
            }
            
            return nil
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                set(encoded, forKey: AppKeys.lastTransaction.rawValue)
            }
        }
    }
}
