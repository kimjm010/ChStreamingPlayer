//
//  SettingViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/11/22.
//

import Differentiator
import RxDataSources
import AVFoundation
import NSObject_Rx
import Foundation
import RxCocoa
import RxSwift


enum VideoType {
    case auto
    case high
    case medium
    case low
}


struct MySetting {
    var header: String
    var items: [Item]
    var isSelectedList: [Bool]
}



extension MySetting: AnimatableSectionModelType {
    typealias Item = String
    
    var identity: String {
        return header
    }
    
    init(original: MySetting, items: [Item]) {
        self = original
        self.items = items
    }
}



struct SettingModel {
    let header: String
    var items: SettingOptions
}



struct SettingOptions {
    let name: String
    var isSelected: Bool
}


var dummySettings = [
    SettingModel(header: "방송 영상 및 소리 옵션", items: SettingOptions(name: "자동(720p)", isSelected: false)),
    SettingModel(header: "방송 영상 및 소리 옵션", items: SettingOptions(name: "720p60", isSelected: false)),
    SettingModel(header: "방송 영상 및 소리 옵션", items: SettingOptions(name: "480p", isSelected: false)),
    SettingModel(header: "방송 영상 및 소리 옵션", items: SettingOptions(name: "360p", isSelected: false)),
    
    SettingModel(header: "", items: SettingOptions(name: "라디오 모드", isSelected: false)),
    SettingModel(header: "", items: SettingOptions(name: "채팅 모드", isSelected: false)),
    
    SettingModel(header: "", items: SettingOptions(name: "백그라운드에서 재생", isSelected: false)),
    
    SettingModel(header: "", items: SettingOptions(name: "낮은 지연 시간 플레이어", isSelected: false))
]

var dummyObservalbe = Observable.just(dummySettings)


class SettingViewController: UIViewController {
    
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Vars
    
    var settings = [
        MySetting(header: "방송 영상 및 소리 옵션",
                  items: ["자동(720p)", "720p60", "480p", "360p"],
                  isSelectedList: [false, false, false, false]),
        MySetting(header: " ",
                  items: ["라디오 모드", "채팅 모드"],
                  isSelectedList: [false, false]),
        MySetting(header: " ",
                  items: ["백그라운드에서 재생"],
                  isSelectedList: [false]),
        MySetting(header: " ",
                  items: ["낮은 지연 시간 플레이어"],
                  isSelectedList: [false, false])
    ]
    
    var dataSource: RxTableViewSectionedAnimatedDataSource<MySetting>?
    static let checkedImage = UIImage(systemName: "checkmark")
    var avPlayer: AVPlayer?
    var isLowBitRate = false
    var isBackgroundPlay = false
    var userVieoQuality = VideoType.auto
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTapBarAppearanceAsDefault()
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<MySetting>(configureCell: {
            (dataSource, tableView, indexPath, item) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "settingTableViewCell") as! settingTableViewCell
                cell.textLabel?.text = "\(item)"
                return cell
        },
        titleForHeaderInSection: { (dataSource, index) in
            return dataSource.sectionModels[index].header
        })
        
        self.dataSource = dataSource
        
        
        // settings 배열을 tableView에 바인딩
//        Observable.just(settings)
//            .bind(to: tableView.rx.items(dataSource: dataSource))
//            .disposed(by: rx.disposeBag)
        
        
        dummyObservalbe.bind(to: tableView.rx.items(cellIdentifier: "settingTableViewCell",
                                                    cellType: settingTableViewCell.self)) { (row, settingModel, cell) in
            cell.settingLabel.text = settingModel.items.name
            cell.checkedImageView.image = SettingViewController.checkedImage
            if settingModel.items.isSelected == false {
                cell.checkedImageView.isHidden = true
            }
        }
        .disposed(by: rx.disposeBag)
        
        
        // 설정 선택 시 이미지 표시
        tableView.rx.itemSelected
            .bind { [weak self]  (indexPath) in
                guard let self = self else { return }
                
                self.tableView.deselectRow(at: indexPath, animated: true)
                let cell = self.tableView.cellForRow(at: indexPath) as! settingTableViewCell

                dummySettings[indexPath.row].items.isSelected = dummySettings[indexPath.row].items.isSelected ? false : true
                cell.checkedImageView.isHidden = dummySettings[indexPath.row].items.isSelected ? false : true
                cell.checkedImageView.isHighlighted = dummySettings[indexPath.row].items.isSelected ? true : false
            }
            .disposed(by: rx.disposeBag)

        
        // 설정 변경
        #warning("Todo: - 셀이 선택 되어있으면(true가 있으면) selection 불가하도록 ???")
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                switch $0.section {
                case 0:
                    if self.settings[0].isSelectedList.contains(true) {
                        print(#fileID, #function, #line, "- \(self.settings)")
                    }
                case 1:
                    if self.settings[1].isSelectedList.contains(false) {
                        #warning("Todo: - 선택하면 기존 선택 삭제하기")
                    }
                case 2:
                    #warning("Todo: - 백그라운드 재생 설정")
                    UserDefaults.standard.setValue(true, forKey: "isBackgroundPlay")
                case 3:
                    // 비트레이트 낮춰서 진행
                    self.avPlayer?.currentItem?.preferredPeakBitRate = 0.1
                    UserDefaults.standard.setValue(true, forKey: "preferredPeakBitRate")
                default:
                    break
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Check User's Preferences
    
    private func checkUserPrefrerences() {
        let userDefaults = UserDefaults.standard
        
        isLowBitRate = userDefaults.bool(forKey: "preferredPeakBitRate")
        isBackgroundPlay = userDefaults.bool(forKey: "isBackgroundPlay")
    }
}
