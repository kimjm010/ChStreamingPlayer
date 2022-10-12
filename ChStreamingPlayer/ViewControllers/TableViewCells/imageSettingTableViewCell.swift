//
//  settingTableViewCell.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/11/22.
//

import UIKit

class imageSettingTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var imageSettingImageView: UIImageView!
    
    
    // MARK: - Configure Cell
    
    func configure(title: String, image: UIImage) {
        settingLabel.text = title
        imageSettingImageView.image = image
    }
}
