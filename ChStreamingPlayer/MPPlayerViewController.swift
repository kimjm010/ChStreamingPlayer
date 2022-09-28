//
//  MPPlayerViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import AVFoundation
import ProgressHUD
import RxAudioVisual
import NSObject_Rx
import RxSwift
import RxCocoa


class MPPlayerViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var moveBackButton: UIButton!
    @IBOutlet weak var moveForwardButton: UIButton!
    @IBOutlet weak var nextVideoButton: UIButton!
    @IBOutlet weak var previousVideoButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var controlZoomButton: UIButton!
    @IBOutlet weak var videoModeLabel: UILabel!
    
    
    // MARK: - Vars
    
    private var playerLooper: NSObject?
    
    private var timeObservetToken: Any?
    
    private var playerItemPresentationSizeObserver: NSKeyValueObservation?
    
    private var playerCurrentItemObserver: NSKeyValueObservation?
    
    var avPlayer = AVQueuePlayer()
    
    var tapGesture = UITapGestureRecognizer()
    
    var isRepeat = false
    
    var isZoom = false
    
    var selectedPreviousItem: AVPlayerItem?
    
    private static let repeatImage = "repeat.1"
    
    private static let finishRepeatImage = "repeat"
    
    private let timeControlStatusRx = BehaviorRelay<AVPlayer.TimeControlStatus>(value: .waitingToPlayAtSpecifiedRate)
    
    
    // MARK: - IBActions
    @IBAction func togglePlay(_ sender: Any) {
        switch avPlayer.timeControlStatus {
            case .playing:
                // player 가 playing중인 경우 멈춤
                avPlayer.pause()
                
            case .paused:
                let currentItem = avPlayer.currentItem
                if currentItem?.currentTime() == currentItem?.duration {
                    currentItem?.seek(to: .zero,  toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                }
                avPlayer.play()
            default:
                avPlayer.pause()
            }
    }
    
    
    /// Play Fast Backward
    @IBAction func moveFastBackward(_ sender: Any) {
        
        // player의 현재 시각이 처음 시각과 같은 경우 재생시간 맨 끝으로 이동
        if avPlayer.currentItem?.currentTime() == .zero {
            if let itemDuration = avPlayer.currentItem?.duration {
                avPlayer.currentItem?.seek(to: itemDuration, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
            }
        }
        
        avPlayer.rate = max(avPlayer.rate - 2.0, -2.0)
    }
    
    
    /// Play Fast Forward
    @IBAction func moveFastForward(_ sender: Any) {
        // player의 현재 시각이 끝 시각과 같은 경우 재생시간 처음으로 이동
        if avPlayer.currentItem?.currentTime() == avPlayer.currentItem?.duration {
            avPlayer.currentItem?.seek(to: .zero, completionHandler: nil)
        }
        
        avPlayer.rate = min(avPlayer.rate + 2.0, 2.0)
    }
    
    
    /// 10초 앞으로 이동
    @IBAction func moveForward(_ sender: Any) {
        if avPlayer.currentItem?.currentTime() == avPlayer.currentItem?.duration {
            avPlayer.advanceToNextItem()
            
            if let currentItem = avPlayer.currentItem {
                self.subscribeCurrentItem(currentItem)
            }
            
            if avPlayer.currentItem == avPlayer.items().last {
                alertAddItemsToPlayer(title: "Alert",
                                      message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in

                    guard let self = self else { return }
                    self.addAllViedeosToPlayer()
                }
            }
        }
        
        let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let newTime = currentTime + 10
        let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    
    /// 10초 앞으로 이동
    @IBAction func moveBackward(_ sender: Any) {
        if avPlayer.currentItem?.currentTime() == .zero {
            if avPlayer.currentItem == avPlayer.items().first {
                ProgressHUD.showFailed("There is no previous video anymore")
            }
            
            avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let newTime = currentTime - 10
        let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    
    /// 이전 재생항목으로 이동
    @IBAction func previousVideo() {
        
        if avPlayer.currentItem?.currentTime() != .zero {
            avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        #warning("Todo: - Previous Item을 저장해서 insert 후 다른 아이템 추가할 것")
        guard let selectedPreviousItem = selectedPreviousItem else { return }
        let currentItems = avPlayer.items()
        
        avPlayer.removeAllItems()
        avPlayer.insert(selectedPreviousItem, after: nil)
        
        for item in currentItems {
            avPlayer.insert(item, after: nil)
        }
    }
    
    
    /// 반복재생
    @IBAction func repeatVideoPlay(_ sender: Any) {
        isRepeat.toggle()
        
        if isRepeat {
            repeatButton.setImage(UIImage(systemName: MPPlayerViewController.repeatImage), for: .normal)
            guard let currentItem = avPlayer.currentItem else { return }
            playerLooper = AVPlayerLooper(player: avPlayer, templateItem: currentItem)
            avPlayer.play()
        } else {
            #warning("Todo: - 반복재생 취소시 다음 재생으로 looper 종료")
            repeatButton.setImage(UIImage(systemName: MPPlayerViewController.finishRepeatImage), for: .normal)
        }
    }
    
    
    @IBAction func controlZoom(_ sender: Any) {
        isZoom.toggle()
        let buttonImage = isZoom ? UIImage(systemName: "minus.magnifyingglass") : UIImage(systemName: "plus.magnifyingglass")
        controlZoomButton.setImage(buttonImage, for: .normal)
        
        
        #if DEBUG
        controlVideoZoom(isZoom: isZoom)
        print(#function, #file, #line, "\(playerView.playerLayer.frame)")
        #endif
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = Bundle.main.url(forResource: "v2", withExtension: "mp4") else { return }
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
        
        addAllViedeosToPlayer()
        addPinchGesturer()
        
        /*
         playPauseButton.rx.tap
             .throttle(0.2, scheduler: MainScheduler.instance)
             .flatMap { self.avPlayer.rx.timeControlStatus }
             .observeOn(MainScheduler.instance)
             .subscribe(onNext: { [unowned self] (status) in
                 switch status {
                 case .playing:
                     avPlayer.pause()
                 case .paused:
                     let currentItem = avPlayer.currentItem
                     if currentItem?.currentTime() == currentItem?.duration {
                         currentItem?.seek(to: .zero,  toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                     }
                     avPlayer.play()
                 default:
                     avPlayer.pause()
                 }
             })
             .disposed(by: rx.disposeBag)
         
         playPauseButton.rx.tap
             .observeOn(MainScheduler.asyncInstance)
             .filter { self.avPlayer.items().count == 0 }
             .flatMap { [unowned self] in self.alertAddItemsToPlayer(title: "Alert",
                                                                     message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") }
             .subscribe(onNext: { [unowned self] (actionType) in
                 switch actionType {
                 case .ok:
                     self.addAllViedeosToPlayer()
                 case .cancel:
                     break
                 }
             })
             .disposed(by: rx.disposeBag)
         */
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
        
        if let timeObservetToken = timeObservetToken {
            avPlayer.removeTimeObserver(timeObservetToken)
            self.timeObservetToken = nil
        }
    }
    
    
    // MARK: - Asset Property Handling
    
    func loadPropertyValues(forAsset newAsset: AVURLAsset) {
        /// Load and test the following asset keys before playback begins.
        let assetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
        
        newAsset.loadValuesAsynchronously(forKeys: assetKeysRequiredToPlay) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.validateValues(forKeys: assetKeysRequiredToPlay, forAsset: newAsset) {
                    self.setupPlayerObservers()
                    self.subscribePlayer(self.avPlayer)
                    if let currentItem = self.avPlayer.currentItem {
                        self.subscribeCurrentItem(currentItem)
                    }
                    self.playerView.player = self.avPlayer
                }
            }
        }
    }
    
    
    func validateValues(forKeys keys: [String], forAsset newAsset: AVAsset) -> Bool {
        for key in keys {
            var error: NSError?
            if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                let stringFormat = NSLocalizedString("The media failed to load the key \"%@\"",
                                                     comment: "You can't use this AVAsset because one of it's keys failed to load.")
                
                let message = String.localizedStringWithFormat(stringFormat, key)
                handleErrorWithMessage(message, error: error)
                
                return false
            }
        }
        
        if !newAsset.isPlayable || newAsset.hasProtectedContent {
            let message = NSLocalizedString("The media isn't playable or it contains protected content.",
                                            comment: "You can't use this AVAsset because it isn't playable or it contains protected content.")
            handleErrorWithMessage(message)
            return false
        }
        
        return true
    }
    
    // MARK: - Key-Value Observing
    
    func setupPlayerObservers() {
        
        /// timeSlider의 value 변경
        timeSlider.rx.value
            .map { Variable(Float($0)) }
            .subscribe(onNext: { [weak self] in
                let newTime = CMTime(seconds: Double($0.value), preferredTimescale: 600)
                self?.avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
            })
            .disposed(by: rx.disposeBag)
        
        
        /// 다음 재생항목으로 이동
        nextVideoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if self.avPlayer.items().count > 1 {
                    self.avPlayer.advanceToNextItem()
                } else {
                    self.alertAddItemsToPlayer(title: "Alert",
                                               message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") { _ in
                        self.addAllViedeosToPlayer()
                    }
                }
            })
            .disposed(by: rx.disposeBag)
       
        
        /// ** CurrentSize Observer -> Swift**
        /*
         // create player current item's presentationSize observer
         playerItemPresentationSizeObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.presentationSize,
                                                        options: [.initial, .new],
                                                        changeHandler: { [weak self] (player, _) in
             guard let self = self else { return }
             guard let currentSize = player.currentItem?.presentationSize else { return }

             print(#fileID, #function, #line, "- currentSize: \(currentSize)")

             DispatchQueue.main.async {
                 self.checkPortraitAndUpdateUI(width: currentSize.width, height: currentSize.height)
             }
         })
         */
        
        
           
        // create player current items observer
//        playerCurrentItemObserver = avPlayer.observe(\.currentItem, changeHandler: { [weak self] (player, _) in
//            guard let self = self else { return }
//
//            if player.items().count == 0 {
//                self.alertAddItemsToPlayer(title: "Alert",
//                                           message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") { _ in
//                    self.addAllViedeosToPlayer()
//                }
//            }
//        })
        
        
//        playPauseButton.rx.tap
//            .flatMap { [unowned self] in self.avPlayer.rx.items() }
//            .map { $0.count }
//            .subscribe(onNext: { [weak self] in
//                guard let self = self else { return }
//
//                if $0 == 0 {
//                    self.alertAddItemsToPlayer(title: "Alert",
//                                               message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") { _ in
//                        self.addAllViedeosToPlayer()
//                    }
//                }
//
//            })
        
    }

    
    // MARK: - Add Videos To Player
    
    private func addAllViedeosToPlayer() {
        var items = [AVPlayerItem]()
        for i in 1...8 {
            guard let url = Bundle.main.url(forResource: "v\(i)", withExtension: "mp4") else { return }
            
            let asset = AVURLAsset(url: url)
            
            let item = AVPlayerItem(asset: asset)
            items.append(item)
            
            avPlayer.insert(item, after: nil)
        }
    }
    
    
    // MARK: - Add Pinch Gesture To Zoom in/out the Video
    
    private func addPinchGesturer() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        playerView.addGestureRecognizer(pinchGesture)
    }
    
    
    /// Pinch제스처를 처리합니다.
    /// - Parameter gestureRecognizer: PinchGesture객체
    @objc
    private func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            guard let view = gestureRecognizer.view else { return }
            
            gestureRecognizer.view?.transform = view.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
        }
    }
    
    
    /// isZoom속성에 따라 화면을 확대/축소합니다.
    /// - Parameter isZoom: 확대 여부 속성
    private func controlVideoZoom(isZoom: Bool) {
        if isZoom {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.playerView.transform = self.playerView.transform.scaledBy(x: 2.0, y: 2.0)
            }
        } else {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.playerView.transform = .identity
            }
        }
    }
}

