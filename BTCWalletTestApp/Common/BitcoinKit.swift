//
//  Bitcoin.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 14.09.2023.
//

import Foundation
import Combine
import BitcoinCore
import BitcoinKit
import HdWalletKit
import HsToolKit

protocol KitEventObservable {
    var publisher: AnyPublisher<BitcoinKitState, Never> { get }
}

protocol BitcoinKitProtocol: KitEventObservable {
    func sync()
    func start()
    func stop()
    func validate(address: String) throws
    func send(to address: String, amount: Decimal) throws -> String
    func getMinSpendableAmount(toAddress: String) -> Decimal?
    func getMaxSpendableAmount(toAddress: String) -> Decimal?
    func getFee(for amount: Decimal, toAddress: String) throws -> Decimal
}

struct BitcoinKitState {
    let balance: BalanceInfo?
    let address: String?
    let syncState: BitcoinCore.KitState
}

final class BitcoinKit: BitcoinKitProtocol {
    enum Rates {
        static let Coin = Decimal.bitcoinRate
        static let Fee = 3
    }
    
    private let kit: Kit
    
    private let subject = PassthroughSubject<BitcoinKitState, Never>()
    
    var address: String {
        kit.receiveAddress()
    }
    
    var balance: BalanceInfo {
        kit.balance
    }
    
    init(mnemonic: [String],
                 purpose: Purpose,
                 syncMode: BitcoinCore.SyncMode,
                 logger: Logger) {
        guard let seed = Mnemonic.seed(mnemonic: mnemonic),
              let kit = try? Kit(seed: seed,
                                 purpose: purpose,
                                 walletId: "DefaultWalletId",
                                 syncMode: .newWallet,
                                 networkType: .testNet,
                                 logger: logger.scoped(with: "BitcoinKit")) else {
            fatalError("Unable to generate Bitcoin Seed / Init Bitcoin KIt")
        }
        
        self.kit = kit
        self.kit.delegate = self
        self.kit.start()
    }
    
    func start() {
        kit.delegate = self
        kit.start()
    }
    
    func stop() {
        kit.stop()
    }
    
    func sync() {
        subject.send(getState())
    }
    
    func validate(address: String) throws {
        try kit.validate(address: address)
    }
    
    func send(to address: String, amount: Decimal) throws -> String {
        let transaction = try kit.send(to: address,
                                       value: getValue(for: amount),
                                       feeRate: BitcoinKit.Rates.Fee,
                                       sortType: .shuffle)
        
        return transaction.header.dataHash.hs.reversedHex
    }
    
    func getMaxSpendableAmount(toAddress: String) -> Decimal? {
        if let spendableAmount = try? kit.maxSpendableValue(toAddress: toAddress,
                                                            feeRate: Rates.Fee) {
            return Decimal(spendableAmount) / Rates.Coin
        }
        
        return nil
    }
    
    func getMinSpendableAmount(toAddress: String) -> Decimal? {
        if let minimalAmount = try? kit.minSpendableValue(toAddress: toAddress) {
            return Decimal(minimalAmount) / Rates.Coin
        }
        
        return nil
    }
    
    func getFee(for amount: Decimal, toAddress: String) throws -> Decimal {
        let fee = try kit.fee(for: getValue(for: amount),
                              toAddress: toAddress,
                              feeRate: Rates.Fee,
                              pluginData: [:])
        return Decimal(fee) / Rates.Coin
    }
}

// MARK: - KitEventObservable

extension BitcoinKit: KitEventObservable {
    var publisher: AnyPublisher<BitcoinKitState, Never> {
        subject.eraseToAnyPublisher()
    }
}

// MARK: - BitcoinCoreDelegate

extension BitcoinKit: BitcoinCoreDelegate {
    func balanceUpdated(balance: BalanceInfo) {
       sync()
    }
    
    func kitStateUpdated(state: BitcoinCore.KitState) {
        sync()
    }
}

// MARK: - Private API

private extension BitcoinKit {
    func getState() -> BitcoinKitState {
        .init(balance: kit.balance,
              address: kit.receiveAddress(),
              syncState: kit.syncState)
    }
    
    func getValue(for amount: Decimal) -> Int {
        let coinValue: Decimal = amount * BitcoinKit.Rates.Coin

        let handler = NSDecimalNumberHandler(roundingMode: .plain,
                                             scale: 0,
                                             raiseOnExactness: false,
                                             raiseOnOverflow: false,
                                             raiseOnUnderflow: false,
                                             raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue)
            .rounding(accordingToBehavior: handler)
            .intValue
    }
}
