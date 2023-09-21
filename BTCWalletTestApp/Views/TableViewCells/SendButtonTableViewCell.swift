//
//  SendButtonTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit

final class SendButtonTableViewCell: UITableViewCell {
    private let btnSend: UIButton = {
        let button = UIButton(configuration: .filled())
        
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var callback: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Selector

@objc extension SendButtonTableViewCell {
    func didTapActionBtn() {
        callback?()
    }
}

// MARK: - Private API

private extension SendButtonTableViewCell {
    func commonInit() {
        configureStackView()
        addButtonAction()
    }
    
    func configureStackView() {
        contentView.addSubview(btnSend)
        
        NSLayoutConstraint.activate([
            btnSend.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .zero),
            btnSend.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0),
            btnSend.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            btnSend.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
    }
    
    func addButtonAction() {
        btnSend.addTarget(self,
                          action: #selector(didTapActionBtn),
                          for: .touchUpInside)
    }
}
