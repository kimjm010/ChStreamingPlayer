//
//  switchSettingTableViewCell.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/12/22.
//

import UIKit

class SwitchSettingTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    
    
    // MARK: - Configure Cell
    
    func configure(title: String, isEnabled: Bool) {
        switchLabel.text = title
        settingSwitch.isOn = isEnabled
    }
}
