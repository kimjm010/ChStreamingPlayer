//
//  SettingViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/11/22.
//

import Differentiator
import RxDataSources
import NSObject_Rx
import Foundation
import RxCocoa
import RxSwift
import AVFoundation


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


class SettingViewController: UIViewController {
    
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Vars
    var settings = [
        MySetting(header: "방송 영상 및 소리 옵션", items: ["자동(720p)", "720p60", "480p", "360p", "160p"], isSelectedList: [false, false, false, false, false]),
        MySetting(header: " ", items: ["라디오 모드", "채팅 모드"], isSelectedList: [false, false]),
        MySetting(header: " ", items: ["백그라운드에서 재생"], isSelectedList: [false]),
        MySetting(header: " ", items: ["낮은 지연 시간 플레이어"], isSelectedList: [false, false])
    ]
    
    var dataSource: RxTableViewSectionedAnimatedDataSource<MySetting>?
    static let checkedImage = UIImage(systemName: "checkmark")
    var avPlayer: AVPlayer?
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        Observable.just(settings)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        
//        Observable.zip(tableView.rx.modelSelected(MySetting.Item.self), tableView.rx.itemSelected)
        
        tableView.rx.itemSelected
            .bind { [weak self]  (indexPath) in
                guard let self = self else { return }
                
                self.tableView.deselectRow(at: indexPath, animated: true)
                let cell = self.tableView.cellForRow(at: indexPath) as! settingTableViewCell
                cell.checkedImageView.image = SettingViewController.checkedImage
                self.settings[indexPath.section].isSelectedList[indexPath.row] = true
            }
            .disposed(by: rx.disposeBag)

        
        // 설정 변경
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                switch $0.section {
                case 0:
                    if self.settings[0].isSelectedList.contains(false) {
                        print(#fileID, #function, #line, "- ")
                    }
                case 1:
                    if self.settings[1].isSelectedList.contains(false) {
                        #warning("Todo: - 선택하면 기존 선택 삭제하기")
                    }
                case 2:
                    #warning("Todo: - 백그라운드 재생 설정")
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
}
