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


#warning("Todo: - 메모리 누수 확인하기")
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
    
    var avPlayer = AVQueuePlayer()
    
    var tapGesture = UITapGestureRecognizer()
    
    var isRepeat = false
    
    var isZoom = false
    
    var selectedPreviousItem: AVPlayerItem?
    
    private static let repeatImage = "repeat.1"
    
    private static let finishRepeatImage = "repeat"
    
    
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
            playerLooper = nil
            repeatButton.setImage(UIImage(systemName: MPPlayerViewController.finishRepeatImage), for: .normal)
        }
    }
    
    
    @IBAction func controlZoom(_ sender: Any) {
        isZoom.toggle()
        let buttonImage = isZoom ? UIImage(systemName: "minus.magnifyingglass") : UIImage(systemName: "plus.magnifyingglass")
        controlZoomButton.setImage(buttonImage, for: .normal)
        controlVideoZoom(isZoom: isZoom)
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = Bundle.main.url(forResource: "v2", withExtension: "mp4") else { return }
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
        
        addAllViedeosToPlayer()
        addPinchGesturer()
        
        
        // 앞으로 10초 이동
        moveForwardButton.rx.tap
            .throttle(0.2, scheduler: MainScheduler.instance)
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.subscribeCurrentItem($0)
                
                if $0.currentTime() == self.avPlayer.currentItem?.duration {
                    self.avPlayer.advanceToNextItem()
                }
                
                if $0 == self.avPlayer.items().last {
                    self.alertAddItemsToPlayer(title: "Alert",
                                          message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in
                        guard let self = self else { return }
                        self.addAllViedeosToPlayer()
                    }
                }
                
                let currentTime = CMTimeGetSeconds(self.avPlayer.currentTime())
                let newTime = currentTime + 10
                let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                self.avPlayer.seek(to: setTime, toleranceBefore: .zero, toleranceAfter: .zero)
            })
            .disposed(by: rx.disposeBag)
        
        // 10초 뒤로 이동
        moveBackButton.rx.tap
            .throttle(0.2, scheduler: MainScheduler.instance)
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                
                let currentTime = CMTimeGetSeconds(self.avPlayer.currentTime())
                let newTime = currentTime - 10
                let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                self.avPlayer.seek(to: setTime, toleranceBefore: .zero, toleranceAfter: .zero)
            })
            .disposed(by: rx.disposeBag)
        
        // 앞으로 감기
        forwardButton.rx.tap
            .throttle(0.2, scheduler: MainScheduler.instance)
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0.currentTime() == .zero {
                    let itemDuration = $0.duration
                    $0.seek(to: itemDuration, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                }
                
                self.avPlayer.rate = min(self.avPlayer.rate + 2.0, 2.0)
            })
            .disposed(by: rx.disposeBag)
        
        // 뒤로 감기
        backwardButton.rx.tap
            .throttle(0.2, scheduler: MainScheduler.instance)
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0.currentTime() == $0.duration {
                    $0.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                }
                
                self.avPlayer.rate = max(self.avPlayer.rate - 2.0, -2.0)
            })
            .disposed(by: rx.disposeBag)
        
        // 다음 영상 재생
        nextVideoButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.items() }
            .map { $0.count }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0 > 1 {
                    self.avPlayer.advanceToNextItem()
                } else {
                    self.alertAddItemsToPlayer(title: "Alert",
                                               message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") { _ in
                        self.addAllViedeosToPlayer()
                    }
                }
            })
            .disposed(by: rx.disposeBag)
        
        // 반복재생
        /*
         repeatButton.rx.tap
             .throttle(0.2, scheduler: MainScheduler.instance)
             .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
             .map { $0.value }
             .ignoreNil()
             .observeOn(MainScheduler.instance)
             .subscribe(onNext: { [weak self] in
                 guard let self = self else { return }

                 self.isRepeat.toggle()

                 if self.isRepeat {
                     self.repeatButton.setImage(UIImage(systemName: MPPlayerViewController.repeatImage), for: .normal)
                     self.playerLooper = AVPlayerLooper(player: self.avPlayer, templateItem: $0)
                 } else {
                     self.avPlayer.pause()
                     self.repeatButton.setImage(UIImage(systemName: MPPlayerViewController.finishRepeatImage), for: .normal)
                 }
             })
             .disposed(by: rx.disposeBag)
         */
        
        // 재생/일시정지
        /*
         playPauseButton.rx.tap
             .flatMap { [unowned self] in self.avPlayer.rx.timeControlStatus }
             .map { $0.rawValue }
             .subscribe(onNext: { [weak self] in
                 guard let self = self else { return }
                 
                 switch $0 {
                 case 0:
                     let currentItem = self.avPlayer.currentItem
                     if currentItem?.currentTime() == currentItem?.duration {
                         currentItem?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                     }
                     self.avPlayer.play()
                 default:
                     self.avPlayer.pause()
                 }
             })
             .disposed(by: rx.disposeBag)
         */
        
        
        // 현재 미디어 아이템을 방출
        avPlayer.rx.currentItem
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.subscribeCurrentItem($0)
            })
            .disposed(by: rx.disposeBag)
        
        /// timeSlider의 value 변경
        timeSlider.rx.value
            .map { Variable(Float($0)) }
            .subscribe(onNext: { [weak self] in
                let newTime = CMTime(seconds: Double($0.value), preferredTimescale: 600)
                self?.avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
            })
            .disposed(by: rx.disposeBag)
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
                    self.subscribePlayer(self.avPlayer)
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

