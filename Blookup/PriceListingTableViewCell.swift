//
//  PriceListingTableViewCell.swift
//  Blookup
//
//  Created by Louis on 2019/6/17.
//  Copyright © 2019 Louis. All rights reserved.
//

import UIKit

class PriceListingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var providerLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
