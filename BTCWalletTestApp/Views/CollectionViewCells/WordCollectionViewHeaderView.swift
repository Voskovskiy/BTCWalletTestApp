//
//  WordCollectionViewHeaderView.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 15.09.2023.
//

import UIKit

final class WordCollectionViewHeaderView: UICollectionReusableView {
    static let reuseIdentifier = String(describing: WordCollectionViewHeaderView.self)
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public API

extension WordCollectionViewHeaderView {
    func configure(with text: String) {
        label.text = text
    }
}

// MARK: - Private API

private extension WordCollectionViewHeaderView {
    func commonInit() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 17.0)
        label.textAlignment = .left
        
        addSubview(label)
        backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            label.topAnchor.constraint(equalTo: bottomAnchor, constant: -8.0)
        ])
    }
}
