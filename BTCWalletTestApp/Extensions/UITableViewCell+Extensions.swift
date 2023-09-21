//
//  UITableViewCell+Extensions.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import UIKit

extension UITableViewCell {
    static var reuseIdentifier: String {
        String(describing: Self.self)
    }
}
