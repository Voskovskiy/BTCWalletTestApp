//
//  SyncStateTableViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit

final class SyncStateTableViewCell: UITableViewCell {
    enum Configuration: Hashable {
        case offline,
             connecting,
             progress(value: String),
             complete
        
        var params: (text: String, color: UIColor) {
            switch self {
            case .offline:
                return ("Offline", .systemRed)
            case .connecting:
                return ("Pending", .tintColor)
            case let .progress(value):
                return ("Syncing(\(value)%)", .tintColor)
            case .complete:
                return ("Synced", .systemGreen)
            }
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
         
         label.text = "Synchronization"
         label.font = .preferredFont(forTextStyle: .headline)
         label.textAlignment = .left
         
         return label
    }()
    
    private let syncLabel: UILabel = {
       let label = UILabel()
        
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .right
        
        return label
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

extension SyncStateTableViewCell {
    func configured(as configuration: SyncStateTableViewCell.Configuration) {
        let params = configuration.params
        
        syncLabel.text = params.text
        syncLabel.textColor = params.color
    }
}

// MARK: - Private API

private extension SyncStateTableViewCell {
    func commonInit() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = .zero
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(syncLabel)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16.0)
        ])
        
        configured(as: .offline)
    }
}
