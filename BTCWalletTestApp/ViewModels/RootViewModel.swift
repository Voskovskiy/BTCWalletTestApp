//
//  RootViewModel.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import Combine
import Foundation
import BitcoinCore

typealias ValidationPublisher = AnyPublisher<CurrentValueValidation, Never>
typealias ValidationSubject = PassthroughSubject<CurrentValueValidation, Never>

protocol CurrentValueObservable {
    var publisher: AnyPublisher<String?, Never> { get }
}

protocol ValidationResultObservable {
    var addressPubliher: ValidationPublisher { get }
    var amountPublisher: ValidationPublisher { get }
    
    func bind(address: CurrentValueObservable)
    func bind(amount: CurrentValueObservable)
}

protocol RootViewModelDiffableDataSourceConfigurable {
    var sections: [RootViewController.Section] { get }
    
    func items(for section: RootViewController.Section) -> [RootViewController.Item]
}

protocol RootVieweModelProtocol: RootViewModelDiffableDataSourceConfigurable,
                                 ValidationResultObservable {
    var output: AnyPublisher<RootViewModel.Output, Never> { get }
    var address: String? { get }
    
    func input(_ input: RootViewModel.Input)
}

final class RootViewModel {
    enum Output {
        case loginRequired,
             refresh(reload: Bool),
             transactionSuccess(hash: String),
             transactionError(message: String)
    }
    
    enum Input {
        case sync,
             refresh,
             clearStoredSendData,
             refreshValidation,
             send,
             login,
             logout
    }
    
    let manager: WalletManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let outputSubject = PassthroughSubject<RootViewModel.Output, Never>()
    private let addressValidationSubject = ValidationSubject()
    private let amountValidationSubject = ValidationSubject()
    
    private(set) var address: String?
    
    private var balance: Decimal?
    private var syncState: BitcoinCore.KitState?
    
    private var storedAddress: String?
    private var storedAmount: String?
    private var storedFee: String?
    
    private var lastTransaction: LastTransaction?
    
    init(manager: WalletManagerProtocol = WalletManager()) {
        self.manager = manager
    }
}

// MARK: - RootViewModelDiffableDataSourceConfigurable

extension RootViewModel: RootViewModelDiffableDataSourceConfigurable {
    var sections: [RootViewController.Section] {
        var sections: [RootViewController.Section] = [.syncState, .balance]
        
        if address != nil {
            sections.append(.address)
        }
        
        if syncState == .synced, balance ?? .zero > .zero {
            sections.append(.send)
        }
        
        if lastTransaction != nil {
            sections.append(.transaction)
        }
        
        return sections
    }
    
    func items(for section: RootViewController.Section) -> [RootViewController.Item] {
        switch section {
        case .balance:
            return [.title(.balance),
                    .balance(getBalanceFormattedAmount())]
        case .syncState:
            return [.syncState(getSyncStateConfig())]
        case .address:
            return [.title(.address),
                    .address(address ?? "")]
        case .send:
            return[.title(.send),
                   .sendAddress(storedAddress ?? ""),
                   .sendAmount(storedAmount),
                   .sendButton]
        case .transaction:
            return [.title(.transaction),
                    .transaction(lastTransaction)]
        }
    }
}

// MARK: - ValidationResultObservable

extension RootViewModel: ValidationResultObservable {
    var addressPubliher: ValidationPublisher {
        addressValidationSubject.eraseToAnyPublisher()
    }
    
    var amountPublisher: ValidationPublisher {
        amountValidationSubject.eraseToAnyPublisher()
    }
    
    func bind(address: CurrentValueObservable) {
        address.publisher.sink { [unowned self] value in
            storedAddress = value
            
            validate(address: value)
            validate(amount: storedAmount)
        }.store(in: &cancellables)
    }
    
    func bind(amount: CurrentValueObservable) {
        amount.publisher.sink { [unowned self] value in
            storedAmount = value?.replacingOccurrences(of: ",", with: ".")
            
            validate(amount: value)
        }.store(in: &cancellables)
    }
}

// MARK: - RootVieweModelProtocol

extension RootViewModel: RootVieweModelProtocol {
    var output: AnyPublisher<Output, Never> {
        outputSubject.eraseToAnyPublisher()
    }
    
    func input(_ input: Input) {
        switch input {
        case .sync:
            sync()
        case .refresh:
            manager.bitcoinKit?.sync()
        case .send:
            send()
        case .login:
            sync(resetKit: true)
        case .logout:
            logout()
        case .clearStoredSendData:
            clearStoredSendData()
        case .refreshValidation:
            validate(address: storedAddress)
            validate(amount: storedAmount)
        }
    }
}

// MARK: - Private API

private extension RootViewModel {
    func sync(resetKit: Bool = false) {
        let settings = UserDefaults.standard
        
        if let phrase = settings.storedMnemonicPhrase,
           settings.loggedIn
        {
            lastTransaction = settings.lastTransaction
            login(with: phrase, resetKit: resetKit)
            return
        }
        
        outputSubject.send(.loginRequired)
    }
    
    func login(with phrase: String, resetKit: Bool = true) {
        manager.login(with: phrase, resetKit: resetKit) { [unowned self] in
            bindBitcoinKit()
            outputSubject.send(.refresh(reload: false))
        }
    }
    
    func send() {
        guard let address = storedAddress else {
            outputSubject.send(.transactionError(message: "Invalid bitcoin address"))
            return
        }
        
        do {
            try manager.bitcoinKit?.validate(address: address)
        } catch {
            outputSubject.send(.transactionError(message: "Invalid bitcoin address"))
            return
        }
        
        guard let stored = storedAmount,
              let amount = Decimal(string: stored) else {
            outputSubject.send(.transactionError(message: "Invalid amount"))
            return
        }
        
        let isUnderMinAmount = isUnderMinSpendableAmount(amount, to: address)
        
        if isUnderMinAmount.isInvalid {
            let btcValue = isUnderMinAmount.message?.withoutMinMaxPrefix() ?? ""
            let message = "Insufficient amount, please use value above: \(btcValue)!"
            outputSubject.send(.transactionError(message: message))
            return
        }
        
        let isOverMaxAmount = isOverMaxSpendableAmount(amount, to: address)
        
        if isOverMaxAmount.isInvalid {
            let btcValue = isOverMaxAmount.message?.withoutMinMaxPrefix() ?? ""
            let message = "Insufficient Funds, available to spend: \(btcValue)!"
            outputSubject.send(.transactionError(message: message))
            return
        }
        
        do {
            if let hash = try manager.bitcoinKit?.send(to: address, amount: amount) {
                lastTransaction = LastTransaction(hash: hash,
                                                  amount: amount.formattedAmount)
                UserDefaults.standard.lastTransaction = lastTransaction
                
                clearStoredSendData()
                
                outputSubject.send(.transactionSuccess(hash: hash))
                return
            }
            
            outputSubject.send(.transactionError(message: "Unexpected Error!"))
        } catch let error {
            outputSubject.send(.transactionError(message: error.localizedDescription))
        }
    }
    
    func logout() {
        UserDefaults.standard.loggedIn = false
        UserDefaults.standard.lastTransaction = nil
        
        manager.logout()
        clearStoredParams()
        
        outputSubject.send(.loginRequired)
    }
    
    func bindBitcoinKit() {
        manager.bitcoinKit?.publisher
            .sink { [weak self] currentState in
                guard let self = self else { return }
                self.balance = Decimal(currentState.balance?.spendable ?? .zero) / BitcoinKit.Rates.Coin
                self.address = currentState.address
                self.syncState = currentState.syncState
                self.outputSubject.send(.refresh(reload: syncState != .synced))
            }.store(in: &cancellables)
    }
    
    func clearStoredParams() {
        balance = nil
        address = nil
        syncState = nil
        lastTransaction = nil
        
        clearStoredSendData()
    }
    
    func clearStoredSendData() {
        storedAmount = nil
        storedAddress = nil
        // Clear validation
        validate(address: nil)
        validate(amount: nil)
        // Refresh list
        outputSubject.send(.refresh(reload: true))
    }
    
    func getBalanceFormattedAmount() -> String {
        (balance ?? .zero).formattedAmount
    }
    
    func getSyncStateConfig() -> SyncStateTableViewCell.Configuration {
        switch syncState {
        case .synced:
            return .complete
        case let .syncing(progress):
            return .progress(value: "\(Int(progress * 100))")
        case .none:
            return .connecting
        default:
            return .offline
        }
    }
    
    func getFee() -> CurrentValueValidation {
        guard let address = storedAddress,
              let storedAmount = storedAmount,
              let _ = try? manager.bitcoinKit?.validate(address: address),
              let value = Decimal(string: storedAmount) else {
            return .pending
        }
        do {
            if let value = try manager.bitcoinKit?.getFee(for: value, toAddress: address) {
                return .valid("Fee: \(value.formattedAmount) BTC")
            }
        } catch {
            if let coreError = error as? BitcoinCoreErrors.SendValueErrors {
                switch coreError {
                case .dust:
                    if let minValue = manager.bitcoinKit?.getMinSpendableAmount(toAddress: address) {
                        return .invalid("MIN: \(minValue.formattedAmount) BTC")
                    }
                case .notEnough:
                    if let maxAmount = manager.bitcoinKit?.getMaxSpendableAmount(toAddress: address) {
                        return .invalid("MAX: \(maxAmount.formattedAmount) BTC")
                    }
                default:
                    break
                }
            }
        }
        return .pending
    }
    
    func isOverMaxSpendableAmount(_ amount: Decimal,
                                  to address: String) -> CurrentValueValidation {
        guard let maxAmount = manager.bitcoinKit?.getMaxSpendableAmount(toAddress: address)
        else {
            return .pending
        }
        return maxAmount < amount
        ? .invalid("MAX: \(maxAmount.formattedAmount) BTC")
        : .valid()
    }
    
    func isUnderMinSpendableAmount(_ amount: Decimal,
                                   to address: String) -> CurrentValueValidation {
        guard let minAmount = manager.bitcoinKit?.getMinSpendableAmount(toAddress: address)
        else {
            return .pending
        }
        return minAmount > amount
        ? .invalid("MIN: \(minAmount.formattedAmount) BTC")
        : .valid()
    }
    
    func isValidAddress(_ address: String) -> CurrentValueValidation.Result {
        do {
            try manager.bitcoinKit?.validate(address: address)
            return .valid
        } catch {
            return .invalid
        }
    }
    
    func validate(address: String?) {
        guard let address else {
            addressValidationSubject.send(.pending)
            return
        }
        
        let result: CurrentValueValidation = isValidAddress(address) == .valid
        ? .valid()
        : .invalid()
        
        addressValidationSubject.send(result)
    }
    
    func validate(amount string: String?) {
        guard let string,
              let amount = Decimal(string: string),
              let address = storedAddress,
        isValidAddress(address) == .valid else {
            amountValidationSubject.send(.pending)
            return
        }
        
        let isUnderMinAmount = isUnderMinSpendableAmount(amount, to: address)
        
        if isUnderMinAmount.isInvalid {
            amountValidationSubject.send(isUnderMinAmount)
            return
        }
        
        let isOverMaxAmount = isOverMaxSpendableAmount(amount, to: address)
        
        if isOverMaxAmount.isInvalid {
            amountValidationSubject.send(isOverMaxAmount)
            return
        }
        
        amountValidationSubject.send(getFee())
    }
}

// MARK: - Private extentions

private extension String {
    func withoutMinMaxPrefix() -> String {
        String(dropFirst(4))
    }
}
