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


struct MySetting {
    var header: String
    var items: [Item]
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
    
    var dataSource: RxTableViewSectionedAnimatedDataSource<MySetting>?
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<MySetting>(configureCell: {
            (dataSource, tableView, indexPath, item) in
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
                cell.textLabel?.text = "\(item)"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "settingTableViewCell") as! settingTableViewCell
                cell.textLabel?.text = "\(item)"
                return cell
            }
            
        },
        titleForHeaderInSection: { (dataSource, index) in
            return dataSource.sectionModels[index].header
        })
        
        self.dataSource = dataSource
        
        
        let sections = [
            MySetting(header: "방송 영상 및 소리 옵션", items: ["자동(720p)", "720p60", "480p", "360p", "160p"]),
            MySetting(header: " ", items: ["라디오 모드", "채팅 모드"]),
            MySetting(header: " ", items: ["백그라운드에서 재생"]),
            MySetting(header: " ", items: ["낮은 지연 시간 플레이어"])
        ]
        
        Observable.just(sections)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        
        Observable.zip(tableView.rx.modelSelected(String.self), tableView.rx.itemSelected)
            .bind { [weak self] (setting, indexPath) in
                guard let self = self else { return }
                
                self.tableView.deselectRow(at: indexPath, animated: true)
                print(#fileID, #function, #line, "- \(setting) \(indexPath) \(sections[indexPath.section].items[indexPath.row])")
            }
            .disposed(by: rx.disposeBag)
    }
}
