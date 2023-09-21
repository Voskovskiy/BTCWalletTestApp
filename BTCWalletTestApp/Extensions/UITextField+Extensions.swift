//
//  UITextField+Extensions.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 19.09.2023.
//

import UIKit
import Combine

extension UITextField {
    var publisher: AnyPublisher<String?, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification,object: self)
            .map { ($0.object as? UITextField)?.text }
            .eraseToAnyPublisher()
    }
}
