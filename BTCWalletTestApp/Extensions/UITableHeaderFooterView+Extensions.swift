//
//  UITableHeaderFooterView+Extensions.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 19.09.2023.
//

import UIKit

extension UITableViewHeaderFooterView {
    static var reuseIdentifier: String {
        String(describing: Self.self)
    }
}
