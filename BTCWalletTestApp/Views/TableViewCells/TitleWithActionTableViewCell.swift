//
//  TitleWithButtonTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit

final class TitleWithActionTableViewCell: UITableViewCell {
    enum Configuration: Hashable {
        case none,
             balance,
             address,
             send,
             transaction
        
        var params: (lblTitle: String, btnTitle: String?) {
            switch self {
            case .none:
                return ("", nil)
            case .balance:
                return ("Balance", "Refresh")
            case .address:
                return ("Address", "Copy")
            case .send:
                return ("Send", "Clear")
            case .transaction:
                return ("Last Transaction", nil)
            }
        }
    }
    
    private let lblTitle: UILabel = {
       let label = UILabel()
        
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .left
        
        return label
    }()
    
    private let btnAction: UIButton = {
       let button = UIButton()
        
        button.setTitleColor(.tintColor, for: .normal)
        button.setTitleColor(.tintColor.withAlphaComponent(0.8), for: .highlighted)
        button.isUserInteractionEnabled = true
        
        return button
    }()
    
    private var callback: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        configured(as: .none)
    }
}

// MARK: - Public API

extension TitleWithActionTableViewCell {
    func configured(as configuration: TitleWithActionTableViewCell.Configuration,
                    action: (() -> Void)? = nil) {
        let params = configuration.params
        
        configureTitleLbl(text: params.lblTitle)
        configureActionBtn(title: params.btnTitle)
        
        callback = action
    }
}

// MARK: - Selector

@objc extension TitleWithActionTableViewCell {
    func didTapActionBtn() {
        callback?()
    }
}

// MARK: - Private API

private extension TitleWithActionTableViewCell {
    func commonInit() {
        configureStackView()
        addButtonAction()
    }
    
    func configureStackView() {
        let stackView = UIStackView()
        
        stackView.axis = .horizontal
        stackView.spacing = .zero
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(lblTitle)
        stackView.addArrangedSubview(btnAction)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
    }
    
    func configureTitleLbl(text: String = "") {
        lblTitle.text = text
    }
    
    func configureActionBtn(title: String? = nil) {
        btnAction.setTitle(title, for: .normal)
        btnAction.alpha = title == nil ? .zero : 1.0
    }
    
    func addButtonAction() {
        btnAction.addTarget(self,
                            action: #selector(didTapActionBtn),
                            for: .touchUpInside)
    }
}
