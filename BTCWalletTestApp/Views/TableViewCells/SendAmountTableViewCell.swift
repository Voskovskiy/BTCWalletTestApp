//
//  SendAmountTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit
import Combine

final class SendAmountTableViewCell: UITableViewCell {
    private let tfAmount: UITextField = {
        let textField = UITextField()
        
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .decimalPad
        textField.placeholder = "example: 0.00000000"
        
        return textField
    }()
    
    private let lblValidation: UILabel = {
        let label = UILabel()
        
        label.font = .preferredFont(forTextStyle: .footnote)
        label.text = " "
        
        return label
    }()
    
    private var token: Cancellable?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITextFieldDelegate

extension SendAmountTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let regex = "^\\d+[\\.\\,]{0,1}+\\d{0,8}$"
        let currentText = textField.text ?? ""
        
        guard !string.isEmpty,
              let stringRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return NSPredicate
            .init(format: "SELF MATCHES %@", regex)
            .evaluate(with: updatedText)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let amountString = tfAmount.text?.replacingOccurrences(of: ",", with: "."),
              let amount = Decimal(string: amountString) else { return }
        tfAmount.text = amount.formattedAmount
    }
}

// MARK: - CurrentValueObservable

extension SendAmountTableViewCell: CurrentValueObservable {
    var publisher: AnyPublisher<String?, Never> { tfAmount.publisher }
}

// MARK: - Public API

extension SendAmountTableViewCell {
    func configure(amount: String?,
                   validationPublisher: ValidationPublisher) {
        tfAmount.text = {
            guard let string = amount,
                  let value = Decimal(string: string) else {
                return amount
            }
                
            return value.formattedAmount
        }()
        
        token = validationPublisher.receive(on: RunLoop.main)
            .sink { [weak self] validation in
                self?.lblValidation.text = validation.message ?? " "
                self?.lblValidation.textColor = validation.isInvalid ? .systemRed : .label
            }
    }
}

// MARK: - Private API

private extension SendAmountTableViewCell {
    func commonInit() {
        let stackView = UIStackView()
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(tfAmount)
        stackView.addArrangedSubview(lblValidation)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .zero),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
        
        tfAmount.delegate = self
    }
}
