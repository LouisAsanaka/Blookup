//
//  PriceListing.swift
//  Blookup
//
//  Created by Louis on 2019/6/17.
//  Copyright © 2019 Louis. All rights reserved.
//

import Foundation
import Money

class PriceListing {
    
    let provider: Book.Provider
    let price: Money?
    let link: String
    
    init(provider: Book.Provider, price: Money?, link: String) {
        self.provider = provider
        self.price = price
        self.link = link
    }
}
