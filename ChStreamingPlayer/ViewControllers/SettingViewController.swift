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


class SettingViewController: UIViewController, UITableViewDelegate {
    
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Vars
    
    private let checkedImage = UIImage(systemName: "checkmark.rectangle")!
    private let unCkeckedImage = UIImage(systemName: "square")
    
    var avPlayer: AVPlayer?
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create setting models
        let sections: [MultipleSectionModel] = [
            .VideoQualitySection(title: "방송 영상 및 소리 옵션", items: [
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "자동(720p)"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "720p60"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "480p"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "360p")]),
            .ModeSection(title: " ", items: [
                .ModeSectionItem(image: UIImage(systemName: "square")!, title: "라디오 모드"),
                .ModeSectionItem(image: UIImage(systemName: "square")!, title: "채팅 모드")]),
            .BackgroundSection(title: " ", items: [
                .BackgroundSectionItem(title: "백그라운드에서 재생", enabled: false)]),
            .LowBitrateSection(title: " ", items: [
                .LowBitrateSectionItem(title: "낮은 지연 시간 플레이어", enabled: false)])
        ]
        
        setTapBarAppearanceAsDefault()
        
        let dataSource = SettingViewController.dataSource()
        
        
        // Bind sections to tableview
        Observable.just(sections)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        
        // 설정 선택 시 이미지 표시
        /*
         Observable.zip(tableView.rx.modelSelected(imageSettingTableViewCell.self), tableView.rx.modelSelected(switchSettingTableViewCell.self), tableView.rx.itemSelected)
             .subscribe(onNext: { [weak self] (imageSetting, switchSetting, indexPath) in
                 guard let self = self else { return }
                 
                 print(#fileID, #function, #line, "- \(imageSetting) \(switchSetting) \(indexPath)")
                 #warning("Todo: - 셀 선택 사항 처리")
             })
             .disposed(by: rx.disposeBag)
         */
        
        
        // Deselect Cell
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                guard let self = self else { return }
                
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: rx.disposeBag)
    }
}




// MARK: - Create Data Source

extension SettingViewController {
    
    /// Create RxTableViewSectionedReloadDataSource
    /// - Returns: DataSource to bind to tableView
    static func dataSource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(configureCell: { (dataSource, tableView, indexPath, _) in
            switch dataSource[indexPath] {
            case let .VideoSectionItem(image, title):
                let cell: imageSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(title: title, image: image)
                return cell
            case let .ModeSectionItem(image, title):
                let cell: imageSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(title: title, image: image)
                return cell
            case let .BackgroundSectionItem(title, enabled):
                let cell: switchSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(title: title, isEnabled: enabled)
                return cell
            case let .LowBitrateSectionItem(title, enabled):
                let cell: switchSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(title: title, isEnabled: enabled)
                return cell
            }
        },
        titleForHeaderInSection: { (dataSource, index) in
            let section = dataSource[index]
            return section.title
        })
    }
}




// MARK: - Section Model

enum MultipleSectionModel {
    case VideoQualitySection(title: String, items: [SectionItem])
    case ModeSection(title: String, items: [SectionItem])
    case BackgroundSection(title: String, items: [SectionItem])
    case LowBitrateSection(title: String, items: [SectionItem])
}




// MARK: - Section Items

enum SectionItem {
    case VideoSectionItem(image: UIImage, title: String)
    case ModeSectionItem(image: UIImage, title: String)
    case BackgroundSectionItem(title: String, enabled: Bool)
    case LowBitrateSectionItem(title: String, enabled: Bool)
}




extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem
    
    var items: [SectionItem] {
        switch self {
        case .VideoQualitySection(title: _, items: let items):
            return items.map { $0 }
        case .ModeSection(title: _, items: let items):
            return items.map { $0 }
        case .BackgroundSection(title: _, items: let items):
            return items.map { $0 }
        case .LowBitrateSection(title: _, items: let items):
            return items.map { $0 }
        }
    }
    
    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case let .VideoQualitySection(title, _):
            self = .VideoQualitySection(title: title, items: items)
            
        case let .ModeSection(title, _):
            self = .ModeSection(title: title, items: items)
            
        case let .BackgroundSection(title, _):
            self = .BackgroundSection(title: title, items: items)
            
        case let .LowBitrateSection(title, _):
            self = .LowBitrateSection(title: title, items: items)
        }
    }
}




extension MultipleSectionModel {
    var title: String {
        switch self {
        case .VideoQualitySection(title: let title, items: _):
            return title
        case .ModeSection(title: let title, items: _):
            return title
        case .BackgroundSection(title: let title, items: _):
            return title
        case .LowBitrateSection(title: let title, items: _):
            return title
        }
    }
}
