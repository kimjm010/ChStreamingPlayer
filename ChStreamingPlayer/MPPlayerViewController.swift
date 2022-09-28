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
    
    private var avPlayer = AVQueuePlayer()
    
    private var playerLooper: NSObject?
    
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    private var timeObservetToken: Any?
    
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    private var playerItemFastForwardObserver: NSKeyValueObservation?
    
    private var playerItemFastReverseObserver: NSKeyValueObservation?
    
    private var playerItemReverseObserver: NSKeyValueObservation?
    
    private var playerItemMoveForwardObserver: NSKeyValueObservation?
    
    private var playerItemMoveBackwardObserver: NSKeyValueObservation?
    
    private var playerItemPresentationSizeObserver: NSKeyValueObservation?
    
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    private var playerCurrentItem: NSKeyValueObservation?
    
    var tapGesture = UITapGestureRecognizer()
    
    var isRepeat = false
    
    var isZoom = false
    
    var landscapeMode: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    var selectedPreviousItem: AVPlayerItem?
    
    private static let pauseImage = "pause.fill"
    
    private static let playImage = "play.fill"
    
    private static let repeatImage = "repeat.1"
    
    private static let finishRepeatImage = "repeat"
    
    private let timeControlStatusRx = BehaviorRelay<AVPlayer.TimeControlStatus>(value: .waitingToPlayAtSpecifiedRate)
    
    
    // MARK: - IBActions
    
    /// Play Video
    @IBAction func togglePlay(_ sender: Any) {
        
        if avPlayer.items().count == 0 {
            alertAddItemsToPlayer(title: "Alert",
                                  message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in
                
                guard let self = self else { return }
                self.addAllViedeosToPlayer()
                self.dismiss(animated: true, completion: nil)
            }
        }
        
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
            DispatchQueue.main.async {
                if self.validateValues(forKeys: assetKeysRequiredToPlay, forAsset: newAsset) {
                    self.setupPlayerObservers()
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
        
        avPlayer.currentItem?.rx.duration
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.durationLabel.text = self.createTimeString(time: Float($0.seconds))
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
        
        
        // play/pause button 이미지 변경
        avPlayer.rx.timeControlStatus.asDriver(onErrorJustReturn: .playing)
            .map { $0 == .playing ? UIImage(systemName: MPPlayerViewController.pauseImage) : UIImage(systemName: MPPlayerViewController.playImage) }
            .drive(playPauseButton.rx.image())
            .disposed(by: rx.disposeBag)
        
        
        // 현재 재생시간 레이블 / slider 변경
        avPlayer.rx.playbackPosition(updateQueue: .main)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                #warning("Todo: - 시작할 때 왜 timevalue가 0.5일까?")
                print(#fileID, #function, #line, "- time value: \($0)")
                self.timeSlider.value = $0
                self.startTimeLabel.text = self.createTimeString(time: $0)
            })
            .disposed(by: rx.disposeBag)
        
        
        /*
         // create player canPlayFastForward observer
         playerItemFastForwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayFastForward,
                                                           options: [.initial, .new],
                                                           changeHandler: { [weak self] (player, _) in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 self.forwardButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
                 self.nextVideoButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
             }
         })
         */
        
        // 빨리감기 가능 여부 확인
        avPlayer.currentItem?.rx.canPlayFastForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                self.forwardButton.isEnabled = $0
                self.nextVideoButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        /*
         // create player canPlayReverse observer
         playerItemReverseObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayReverse,
                                                       options: [.new, .initial]) { [weak self] (player, _) in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 self.backwardButton.isEnabled = player.currentItem?.canPlayReverse ?? false
                 self.previousVideoButton.isEnabled = player.currentItem?.canPlayReverse ?? false
             }
         }
         */
        
        
        // 되감기 가능 여부 확인
        avPlayer.currentItem?.rx.canPlayReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                self.backwardButton.isEnabled = $0
                self.previousVideoButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        /*
         // create player canStepForward observer
         playerItemMoveForwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canStepForward,
                                                           options: [.initial, .new],
                                                           changeHandler: { [weak self] (player, _) in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 self.moveForwardButton.isEnabled = player.currentItem?.canStepForward ?? false
             }
         })
         */
        
        
        // 앞으로 이동 가능 여부 확인
        avPlayer.currentItem?.rx.canStepForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                self.moveForwardButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        /*
         // create player canStepBackward observer
         playerItemMoveBackwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canStepBackward,
                                                            options: [.initial, .new],
                                                            changeHandler: { [weak self] (player, _) in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 self.moveBackButton.isEnabled = player.currentItem?.canStepBackward ?? false
             }
         })
         */
        
        
        // 뒤로 이동 가능 여부 확인
        avPlayer.currentItem?.rx.canStepBackward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                self.moveBackButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        /*
         // create player canPlayFastReverse observer
         playerItemFastReverseObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayFastReverse,
                                                           options: [.new, .initial]) { [weak self] (player, _) in
             guard let self = self else { return }

             DispatchQueue.main.async {
                 self.backwardButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
                 self.repeatButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
             }
         }
         */
        
        
        // 뒤로 이동 가능 여부 확인
        avPlayer.currentItem?.rx.canPlayFastReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                self.backwardButton.isEnabled = $0
                self.repeatButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        
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
        
        
        #warning("Todo: - 다음 비디오 재생 시 이벤트를 방출하지 않는다....")
        avPlayer.currentItem?.rx.presentation()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                print(#fileID, #function, #line, "- size: \($0)")
                
                self.videoModeLabel.text = $0.width > $0.height ? "Landscape Mode" : "Portrait Mode"
            })
            .disposed(by: rx.disposeBag)
        
        
        /// playerItem Status에 따라 버튼 UI 변경
        avPlayer.currentItem?.rx.status()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                switch $0 {
                case .failed:
                    self.updateUIForPlayerItemFailedState()
                case .readyToPlay:
                    self.updateUIForPlayerItemReadyToPlayState()
                default:
                    self.updateUIForPlayerItemDefaultState()
                }
            })
            .disposed(by: rx.disposeBag)
        
           
        // create player current items observer
        playerCurrentItem = avPlayer.observe(\.currentItem, changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
            if player.items().count == 0 {
                self.alertAddItemsToPlayer(title: "Alert",
                                           message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") { _ in
                    self.addAllViedeosToPlayer()
                }
            }
        })
    }
    
    
    // MARK: - Update UI based on Player Item Status
    
    /// playerItem이 fail인 경우 표시할 UI
    private func updateUIForPlayerItemFailedState() {
        playPauseButton.isEnabled = false
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackButton.isEnabled = false
        moveForwardButton.isEnabled = false
        nextVideoButton.isEnabled = false
        previousVideoButton.isEnabled = false
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
        ProgressHUD.showFailed("Error ocurred when playing video. Please try again later.")
    }
    
    
    /// playerItem이 readyToPlay인 경우 표시할 UI
    private func updateUIForPlayerItemReadyToPlayState() {
        guard let currentItem = avPlayer.currentItem else { return }
        
        playPauseButton.isEnabled = true
        moveBackButton.isEnabled = true
        moveForwardButton.isEnabled = true
        nextVideoButton.isEnabled = true
        previousVideoButton.isEnabled = true
        forwardButton.isEnabled = true
        backwardButton.isEnabled = true
        
        let newDurationSeconds = Float(currentItem.duration.seconds)
        let currentTimes = Float(CMTimeGetSeconds(avPlayer.currentTime()))
        
        timeSlider.maximumValue = newDurationSeconds
        timeSlider.value = currentTimes
        timeSlider.isEnabled = true
        startTimeLabel.isEnabled = true
        startTimeLabel.text = createTimeString(time: currentTimes)
        durationLabel.isEnabled = true
        durationLabel.text = createTimeString(time: newDurationSeconds)
    }
    
    
    /// playerItem의 기본 UI
    private func updateUIForPlayerItemDefaultState() {
        playPauseButton.isEnabled = false
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackButton.isEnabled = false
        moveForwardButton.isEnabled = false
        nextVideoButton.isEnabled = false
        previousVideoButton.isEnabled = false
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
    }
    
    private func updateUIForPlayerItemStatus() {
        guard let currentItem = avPlayer.currentItem else { return }
        
        switch currentItem.status {
        case .failed:
            playPauseButton.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            durationLabel.isEnabled = false
            moveBackButton.isEnabled = false
            moveForwardButton.isEnabled = false
            nextVideoButton.isEnabled = false
            previousVideoButton.isEnabled = false
            forwardButton.isEnabled = false
            backwardButton.isEnabled = false
            ProgressHUD.showFailed("Error ocurred when playing video. Please try again later.")
            
        case .readyToPlay:
            playPauseButton.isEnabled = true
            moveBackButton.isEnabled = true
            moveForwardButton.isEnabled = true
            nextVideoButton.isEnabled = true
            previousVideoButton.isEnabled = true
            forwardButton.isEnabled = true
            backwardButton.isEnabled = true
            
            let newDurationSeconds = Float(currentItem.duration.seconds)
            let currentTimes = Float(CMTimeGetSeconds(avPlayer.currentTime()))
            
            timeSlider.maximumValue = newDurationSeconds
            timeSlider.value = currentTimes
            timeSlider.isEnabled = true
            startTimeLabel.isEnabled = true
            startTimeLabel.text = createTimeString(time: currentTimes)
            durationLabel.isEnabled = true
            durationLabel.text = createTimeString(time: newDurationSeconds)
            
        default:
            playPauseButton.isEnabled = false
            timeSlider.isEnabled = false
            startTimeLabel.isEnabled = false
            durationLabel.isEnabled = false
            moveBackButton.isEnabled = false
            moveForwardButton.isEnabled = false
            nextVideoButton.isEnabled = false
            previousVideoButton.isEnabled = false
            forwardButton.isEnabled = false
            backwardButton.isEnabled = false
        }
    }
    
    
    // MARK: - Convert Time to String
    
    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
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
    
    
    // MARK: - Check the Video Mode and Update UI
    
    /// 가로/세로모드 확인 후 UI업데이트
    /// - Parameters:
    ///   - width: 비디오의 가로 크기
    ///   - height: 비디오의 세로 크기
    private func checkPortraitAndUpdateUI(width: Double, height: Double) {
        var isPortrait: Bool?
        
        if width > height {
            isPortrait = false
            setPortraitMode(isPortrait: isPortrait)
        } else {
            isPortrait = true
            setPortraitMode(isPortrait: isPortrait)
        }
    }
    
    
    // MARK: - Adjust UI to Portrait Mode or Landscape Mode
    
    /// 비디오 가로/세로모드를 사용자에게 표시합니다.
    /// - Parameter isPortrait: 세로모드 Bool속성
    private func setPortraitMode(isPortrait: Bool?) {
        guard let isPortrait = isPortrait else { return }
        
        if !isPortrait {
            videoModeLabel.text = "Landscape Mode"
        } else {
            videoModeLabel.text = "Portrait Mode"
        }
    }
    
    
    // MARK: - 비디오 재생 목록이 없는 경우 nextVideo버튼 비활성화
    
    /// Disable Next Video Button if there is no Video items to play
    private func disableNextVideoButton() {
        nextVideoButton.isEnabled = false
    }
}

