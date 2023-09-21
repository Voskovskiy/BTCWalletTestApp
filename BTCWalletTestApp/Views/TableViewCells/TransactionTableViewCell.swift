//
//  TransactionTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit

final class TransactionTableViewCell: UITableViewCell {
    private let tvHash: UITextView = {
        let textView = UITextView()
        
        textView.tintColor = .tintColor
        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .callout)
        textView.textAlignment = .center
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainer.maximumNumberOfLines = 2
        
        return textView
    }()
    
    private let lblAmount: UILabel = {
        let label = UILabel()
         
         label.text = "0.00000000"
         label.font = .preferredFont(forTextStyle: .largeTitle)
         label.textAlignment = .left
         label.translatesAutoresizingMaskIntoConstraints = false
         
         return label
    }()
    
    private let btnCopy: UIButton = {
        let button = UIButton(configuration: .filled())
        
        button.setTitle("Copy Hash", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.isUserInteractionEnabled = true
        
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public API

extension TransactionTableViewCell {
    func configure(with transaction: LastTransaction?) {
        guard let transaction else { return }
        
        lblAmount.text = "BTC: \(transaction.amount)"
        tvHash.text = transaction.hash
    }
}

// MARK: - Private API

private extension TransactionTableViewCell {
    func commonInit() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8.0
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(lblAmount)
        stackView.addArrangedSubview(tvHash)
        stackView.addArrangedSubview(btnCopy)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
        
        btnCopy.addTarget(self,
                             action: #selector(didTapCopy),
                             for: .touchUpInside)
    }
    
    @objc
    func didTapCopy() {
        guard let hash = tvHash.text, !hash.isEmpty else { return }
        UIPasteboard.general.string = hash
    }
}
