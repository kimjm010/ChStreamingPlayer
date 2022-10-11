//
//  settingTableViewCell.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/11/22.
//

import UIKit

class settingTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var settingSwitch: UISwitch!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        settingSwitch.isOn = false
    }
}
