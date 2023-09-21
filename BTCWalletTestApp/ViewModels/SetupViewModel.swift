//
//  SetupViewModel.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import Foundation
import Combine
import HdWalletKit

protocol SetupViewModelProtocol {
    var publisher: AnyPublisher<SetupViewModel.Output, Never> { get }
    var selectedState: SetupViewModel.SelectionState { get }
    
    mutating func input(_ input: SetupViewModel.Input)
}

struct SetupViewModel: SetupViewModelProtocol {
    enum Input {
        case didSelect(_ word: String),
             didSelectGenerate,
             didConfirm,
             sync
    }
    
    enum Output {
        case didUpdate(_ selectedWords: [String],_ available: [String])
        case didFinish(_ phrase: String)
    }
    
    enum SelectionState {
        case pending,
             complete,
             error
    }
    
    private let wordlist = Mnemonic.wordList(for: .english).map { String($0) }
    private let subject = PassthroughSubject<SetupViewModel.Output, Never>()
    
    private var state = SetupViewModel.SelectionState.pending
    private var selectedWords = [String]()
    
    var publisher: AnyPublisher<Output, Never> {
        subject.eraseToAnyPublisher()
    }
    
    var selectedState: SelectionState {
        state
    }
    
    mutating func input(_ input: Input) {
        switch input {
        case .didSelect(let word):
            selectedWords.isEmpty || !selectedWords.contains(word)
            ? add(word: word)
            : remove(word: word)
        case .didSelectGenerate:
            generate()
        case .didConfirm where isFull:
            let phrase = selectedWords.joined(separator: " ")
            subject.send(.didFinish(phrase))
            return
        case .didConfirm:
            updateSelection(isError: true)
            return
        case .sync:
            sync()
        }
        
        updateSelection()
    }
}

// MARK: - Private API

private extension SetupViewModel {
    var isFull: Bool {
        selectedWords.count == Mnemonic.WordCount.twelve.rawValue
    }
    
    mutating func add(word: String) {
        guard wordlist.contains(word),
              !selectedWords.contains(word) else {
            return assertionFailure("Unexpected input - \(word)")
        }
        
        if isFull { return }
        
        selectedWords.append(word)
    }
    
    mutating func remove(word: String) {
        guard let index = selectedWords.firstIndex(of: word) else {
            return assertionFailure("Unexpected input - \(word)")
        }
        
        selectedWords.remove(at: index)
    }
    
    mutating func generate() {
        guard let generatedSelection = try? Mnemonic.generate() else { return }
        selectedWords = generatedSelection
    }
    
    mutating func sync() {
        guard let storedMnemonicPhrase = UserDefaults.standard.storedMnemonicPhrase,
              UserDefaults.standard.loggedIn
        else {
            generate()
            return
        }
        
        selectedWords = storedMnemonicPhrase
            .lazy
            .split(separator: " ")
            .map { String($0) }
    }
    
    mutating func updateState(_ isError: Bool) {
        if isError {
            state = .error
            return
        }
        state = isFull ? .complete : .pending
    }
    
    mutating func updateSelection(isError: Bool = false) {
        let available: [String] = {
            selectedWords.isEmpty
            ? wordlist
            : wordlist.filter { !selectedWords.contains($0) }
        }()
        
        updateState(isError)
        
        subject.send(.didUpdate(selectedWords, available))
    }
}
