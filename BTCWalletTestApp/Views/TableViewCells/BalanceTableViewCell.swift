//
//  BalanceTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit

final class BalanceTableViewCell: UITableViewCell {    
    private let lblBalance: UILabel = {
       let label = UILabel()
        
        label.text = "0.00000000"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ value: String) {
        lblBalance.text = value
    }
}

// MARK: - Private API

private extension BalanceTableViewCell {
    func commonInit() {
        
        contentView.addSubview(lblBalance)
        
        NSLayoutConstraint.activate([
            lblBalance.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -8.0),
            lblBalance.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            lblBalance.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            lblBalance.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
    }
}
