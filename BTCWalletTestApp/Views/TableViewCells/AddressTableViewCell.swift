//
//  AddressTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit

final class AddressTableViewCell: UITableViewCell {
    private let tvAddress: UITextView = {
        let textView = UITextView()
        
        textView.tintColor = .tintColor
        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textAlignment = .center
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        return textView
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

extension AddressTableViewCell {
    func configure(_ text: String) {
        tvAddress.text = text
    }
}


// MARK: - Private API

private extension AddressTableViewCell {
    func commonInit() {
        contentView.addSubview(tvAddress)
        
        NSLayoutConstraint.activate([
            tvAddress.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8.0),
            tvAddress.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            tvAddress.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            tvAddress.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
    }
}

