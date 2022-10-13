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
    let resolutionObservable = BehaviorSubject<CGSize>(value: CGSize(width: 0.0, height: 0.0))
    let bitRateObservable = BehaviorSubject<Bool>(value: false)
    var avPlayer: AVPlayer?
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeData()
        
        // create setting models
        var sections: [MultipleSectionModel] = [
            .VideoQualitySection(title: "방송 영상 및 소리 옵션", items: [
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "자동(720p)"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "720p60"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "480p"),
                .VideoSectionItem(image: UIImage(systemName: "square")!, title: "360p")]),
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
         Observable.zip(tableView.rx.modelSelected(MultipleSectionModel.self), tableView.rx.itemSelected)
             .subscribe(onNext: { [weak self] (sectionModel, indexPath) in
                 guard let self = self else { return }
                 
                 sections[indexPath.section].items[indexPath.row]
                 
             })
             .disposed(by: rx.disposeBag)
        
        Observable.just(tableView.rx.modelSelected(MultipleSectionModel.self))
            .subscribe(onNext: {
                print(#fileID, #function, #line, "- \($0)")
            })
            .disposed(by: rx.disposeBag)
         */
        
        
        // Deselect Cell
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                guard let self = self else { return }
                
                self.tableView.deselectRow(at: indexPath, animated: true)
                
                switch indexPath.section {
                case 0:
                    self.selectResolution(indexPath.row)
                default:
                    break
                }
            })
            .disposed(by: rx.disposeBag)
        
        
        // Subscribe switchObservable isOn value
        
        SwitchSettingTableViewCell.switchObservable
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                print(#fileID, #function, #line, "- \($0)")
                self.changeBitRate($0)
            })
            .disposed(by: self.rx.disposeBag)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Setting Player Item's Maximum Resolution
        
        resolutionObservable
            .map { CGSize(width: $0.width, height: $0.height) }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.avPlayer?.currentItem?.preferredMaximumResolution = $0
            })
            .disposed(by: rx.disposeBag)
        
        
        // Change player item's Bit Rate
        
        bitRateObservable
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.avPlayer?.currentItem?.preferredPeakBitRate = $0 ? 0.1 : 1.0
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Initialize Data
    
    /// Initialize Data
    private func initializeData() {
        let widthResolution = UserDefaults.standard.double(forKey: "widthResolution")
        let heightResolution = UserDefaults.standard.double(forKey: "heightResolution")
        avPlayer?.currentItem?.preferredMaximumResolution = CGSize(width: widthResolution, height: heightResolution)
    }
    
    
    // MARK: - Change Video Resoultion
    
    /// Select Video Resoultion
    ///
    /// - Parameter indexPath: IndexPath of TableView
    private func selectResolution(_ indexPath: Int) {
        var resolution = CGSize(width: 0.0, height: 0.0)
        
        switch indexPath {
        case 0, 1:
            resolution = CGSize(width: 1280, height: 720)
        case 2:
            resolution = CGSize(width: 854, height: 480)
        case 3:
            resolution = CGSize(width: 640, height: 360)
        default:
            break
        }
        
        resolutionObservable.onNext(resolution)
    }
    
    
    // MARK: - Emit Changed Video BitRate
    
    /// Change the Video Bit Rate if the cell is selected
    ///
    /// - Parameter cell: selected Cell(SwitchTableViewCell)
    private func changeBitRate(_ changed: Bool = false) {
        bitRateObservable.onNext(changed)
    }
}




// MARK: - Create Data Source

extension SettingViewController {
    
    /// Create RxTableViewSectionedReloadDataSource
    ///
    /// - Returns: DataSource to bind to tableView
    static func dataSource() -> RxTableViewSectionedReloadDataSource<MultipleSectionModel> {
        return RxTableViewSectionedReloadDataSource<MultipleSectionModel>(configureCell: { (dataSource, tableView, indexPath, _) in
            switch dataSource[indexPath] {
            case let .VideoSectionItem(image, title):
                let cell: ImageSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configure(title: title, image: image)
                return cell
            case let .LowBitrateSectionItem(title, enabled):
                let cell: SwitchSettingTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
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
    case LowBitrateSection(title: String, items: [SectionItem])
}




// MARK: - Section Items

enum SectionItem {
    case VideoSectionItem(image: UIImage, title: String)
    case LowBitrateSectionItem(title: String, enabled: Bool)
}




extension MultipleSectionModel: SectionModelType {
    typealias Item = SectionItem
    
    var items: [SectionItem] {
        switch self {
        case .VideoQualitySection(title: _, items: let items):
            return items.map { $0 }
        case .LowBitrateSection(title: _, items: let items):
            return items.map { $0 }
        }
    }
    
    init(original: MultipleSectionModel, items: [Item]) {
        switch original {
        case let .VideoQualitySection(title, _):
            self = .VideoQualitySection(title: title, items: items)
            
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
        case .LowBitrateSection(title: let title, items: _):
            return title
        }
    }
}
