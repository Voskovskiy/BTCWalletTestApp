//
//  WordCollectionViewCell.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit

final class WordCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: WordCollectionViewCell.self)
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        label.text?.removeAll()
        contentView.backgroundColor = .tintColor
    }
}

// MARK: - Public API

extension WordCollectionViewCell {
    func configure(with item: SetupCellItem) {
        label.text = item.word
        contentView.backgroundColor = item.color
    }
}

// MARK: - Private API

private extension WordCollectionViewCell {
    func commonInit() {
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 8.0
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = .white
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4.0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0)
        ])
    }
}
