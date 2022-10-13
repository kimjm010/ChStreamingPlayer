//
//  switchSettingTableViewCell.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/12/22.
//

import NSObject_Rx
import RxSwift
import UIKit


class SwitchSettingTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    
    
    // MARK: - Observable
    
    static let switchObservable = BehaviorSubject<Bool>(value: false)
    
    
    // MARK: - Emit settingSwitch isOn value
    
    override func awakeFromNib() {
        
        settingSwitch.rx.isOn
            .subscribe(onNext: {
                SwitchSettingTableViewCell.switchObservable.onNext($0)
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Configure Cell
    
    func configure(title: String, isEnabled: Bool) {
        switchLabel.text = title
        settingSwitch.isOn = isEnabled
    }
}
