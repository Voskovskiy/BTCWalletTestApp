//
//  SendAddressTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit
import Combine

final class SendAddressTableViewCell: UITableViewCell {    
    private let tfAddress: UITextField = {
        let textField = UITextField()
        
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .default
        textField.placeholder = "example: tb1qw2c3lxufxqe2x9s4rdzh65tpf4d7fssjgh8nv6"
        
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

// MARK: - CurrentValueObservable

extension SendAddressTableViewCell: CurrentValueObservable {
    var publisher: AnyPublisher<String?, Never> { tfAddress.publisher }
}

// MARK: - Public API

extension SendAddressTableViewCell {
    func configure(address text: String?,
                   validationPublisher: ValidationPublisher) {
        tfAddress.text = text
        
        token = validationPublisher.receive(on: RunLoop.main)
            .sink { [weak self] validation in
                self?.lblValidation.text = validation.message ?? " "
                self?.lblValidation.textColor = validation.color
            }
    }
}

// MARK: - Private API

private extension SendAddressTableViewCell {
    func commonInit() {
        let stackView = UIStackView()
        
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(tfAddress)
        stackView.addArrangedSubview(lblValidation)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .zero),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
    }
}
