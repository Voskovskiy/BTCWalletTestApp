//
//  LastTransaction.swift
//  BTCWalletTestApp
//
//  Created by Konstyantyn Voskovskyi on 18.09.2023.
//

import Foundation

struct LastTransaction: Codable, Hashable {
    let hash: String
    let amount: String
}
