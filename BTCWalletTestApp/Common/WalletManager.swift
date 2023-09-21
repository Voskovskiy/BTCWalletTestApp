//
//  WalletManager.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 14.09.2023.
//

import Foundation
import Combine
import BitcoinKit

protocol SessionManageable {
    var bitcoinKit: BitcoinKitProtocol? { get }
    
    func sync()
    func login(with phrase: String,
               resetKit: Bool,
               completion: @escaping () -> Void)
    func logout()
}

protocol WalletManagerProtocol: SessionManageable {}

final class WalletManager: WalletManagerProtocol {
    private(set) var bitcoinKit: BitcoinKitProtocol? = nil
    private let queue = DispatchQueue(label: "WalletManager.BitcoinKit.Queue",
                                      qos: .userInitiated)
}

// MARK: - SessionManageable

extension WalletManager: SessionManageable {
    func sync() {
        bitcoinKit?.sync()
    }
    
    func login(with phrase: String,
               resetKit: Bool = true,
               completion: @escaping () -> Void) {
        if resetKit {
            try? Kit.clear()
        }
        
        queue.async {
            self.bitcoinKit = BitcoinKit(mnemonic: phrase.components(separatedBy: " "),
                                         purpose: .bip84,
                                         syncMode: .newWallet,
                                         logger: .init(minLogLevel: .verbose))
            completion()
        }
    }
    
    func logout() {
        bitcoinKit?.stop()
        bitcoinKit = nil
    }
}
