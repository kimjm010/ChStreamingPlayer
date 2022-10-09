//
//  MPPlayerViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import AVFoundation
import ProgressHUD
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
    @IBOutlet weak var moveBackwardButton: UIButton!
    @IBOutlet weak var moveForwardButton: UIButton!
    @IBOutlet weak var nextVideoButton: UIButton!
    @IBOutlet weak var previousVideoButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var controlZoomButton: UIButton!
    @IBOutlet weak var videoModeLabel: UILabel!
    @IBOutlet var pinchGesture: UIPinchGestureRecognizer!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    
    // MARK: - Vars
    
    lazy var isZoomObservable = Observable.just(self.isZoom)
    private static let repeatImage = "repeat.1"
    private static let finishRepeatImage = "repeat"
    var currentItemsForPlayer = [AVPlayerItem]()
    var currentItemIndex: Int?
    var selectedPreviousItem: AVPlayerItem?
    private var playerLooper: NSObject?
    private var timeObserverToken: Any?
    var avPlayer = AVPlayer()
    var isRepeat = false
    var isZoom = false
    
    
    //MARK: - Disposables
    
    var presentationDisposable: Disposable? = nil
    var canPlayFastForwardDisposable: Disposable? = nil
    var canPlayReverseDisposable: Disposable? = nil
    var canStepForwardDisposable: Disposable? = nil
    var canStepBackwardDisposable: Disposable? = nil
    var canPlayFastReverseDisposable: Disposable? = nil
    var statusDisposable: Disposable? = nil
    var durationDisposable: Disposable? = nil
    var timeControlStatusDisposable: Disposable? = nil
    var playbackPositionDisposable: Disposable? = nil
    var playerItemsDisposable: Disposable? = nil
    var playerTimeControlStatusDisposable: Disposable? = nil
    
    
    // MARK: - IBActions
    @IBAction func togglePlay(_ sender: Any) {
        switch avPlayer.timeControlStatus {
            case .playing:
                // player 가 playing중인 경우 멈춤
                avPlayer.pause()

            case .paused:
                let currentItem = avPlayer.currentItem
                if currentItem?.currentTime() == currentItem?.duration {
                    currentItem?.seek(to: .zero, completionHandler: nil)
                }
                avPlayer.play()
            default:
                avPlayer.pause()
        }
    }
    
    
    /// 이전 재생항목으로 이동
    @IBAction func previousVideo() {
        if avPlayer.currentItem?.currentTime() != .zero {
            avPlayer.seek(to: .zero)
        }
    }
    
    
    /// 반복재생
    @IBAction func repeatVideoPlay(_ sender: Any) {
//        isRepeat.toggle()
//
//        if isRepeat {
//            repeatButton.setImage(UIImage(systemName: MPPlayerViewController.repeatImage), for: .normal)
//            guard let currentItem = avPlayer.currentItem else { return }
//            playerLooper = AVPlayerLooper(player: avPlayer, templateItem: currentItem)
//            avPlayer.play()
//        } else {
//            playerLooper = nil
//            repeatButton.setImage(UIImage(systemName: MPPlayerViewController.finishRepeatImage), for: .normal)
//            avPlayer.play()
//        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 비디오 구성
        guard let url = Bundle.main.url(forResource: "v2", withExtension: "mp4") else { return }
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
        addAllViedeosToPlayer()
        
        addPinchGesturer()
        addDoubleTapGesture()
        
        #if DEBUG
        avPlayer.replaceCurrentItem(with: currentItemsForPlayer[0])
        #endif
        
        
        // 현재 미디어 아이템을 방출
        avPlayer.rx.currentItem
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.subscribePlayer(self.avPlayer)
                self.subscribeCurrentItem($0)
                
                /// Save Current Item Index
                self.currentItemIndex = self.currentItemsForPlayer.firstIndex(of: $0)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 재생/일시정지
        /*
         timeControlStatusDisposable = nil
         
         timeControlStatusDisposable = playPauseButton.rx.tap
              .flatMap { [unowned self] in self.avPlayer.rx.timeControlStatus }
              .debug()
              .map { $0.rawValue }
              .debug()
              .subscribe(onNext: { [weak self] in
                  guard let self = self else { return }
                  print(#fileID, #function, #line, "- \($0)")
                  switch $0 {
                  case 0:
                      let currentItem = self.avPlayer.currentItem
                      if currentItem?.currentTime() == currentItem?.duration {
                          currentItem?.seek(to: .zero, completionHandler: nil)
                      }
                      self.avPlayer.play()
                  default:
                      self.avPlayer.pause()
                  }
              })
         */
        
        
        // 앞으로 10초 이동
        moveForwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: {
                
                print(#fileID, #function, #line, "- \($0)")
                
                let currentTime = CMTimeGetSeconds($0.currentTime())
                let newTime = currentTime + 10
                let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                $0.seek(to: setTime, completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 10초 뒤로 이동
        moveBackwardButton.rx.tap
            .debug()
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.avPlayer.seek(to: .zero)
                
                let currentTime = CMTimeGetSeconds(self.avPlayer.currentTime())
                let newTime = currentTime - 10
                let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                self.avPlayer.currentItem?.seek(to: setTime, completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 앞으로 감기
        forwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0.currentTime() == .zero {
                    let itemDuration = $0.duration
                    $0.seek(to: itemDuration, completionHandler: nil)
                }
                
                self.avPlayer.rate = min(self.avPlayer.rate + 2.0, 2.0)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 뒤로 감기
        backwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0.currentTime() == $0.duration {
                    $0.seek(to: .zero, completionHandler: nil)
                }
                
                self.avPlayer.rate = max(self.avPlayer.rate - 2.0, -2.0)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 다음 영상 재생
        nextVideoButton.rx.tap
            .debug()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.playNextVideo(self.avPlayer)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 이전 영상 재생
        previousVideoButton.rx.tap
            .debug()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.playPreviousVideo(self.avPlayer)
            })
            .disposed(by: rx.disposeBag)
        
        
        // timeSlider 재생 위치 조정
        timeSlider.rx.value
            .map { Variable(Float($0)) }
            .subscribe(onNext: { [weak self] in
                let newTime = CMTime(seconds: Double($0.value), preferredTimescale: 600)
                self?.avPlayer.seek(to: newTime)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 확대, 축소기능
        controlZoomButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.isZoom.toggle()
                
                self.controlVideoZoom(isZoom: self.isZoom)
                let buttonImage = self.isZoom ? UIImage(systemName: "minus.magnifyingglass") : UIImage(systemName: "plus.magnifyingglass")
                self.controlZoomButton.setImage(buttonImage, for: .normal)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 반복재생
        /*
         repeatButton.rx.tap
             .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
             .debug()
             .map { $0.value }
             .debug()
             .ignoreNil()
             .debug()
             .subscribe(onNext: { [weak self] in
                 guard let self = self else { return }

                 self.isRepeat.toggle()
                 print(#fileID, #function, #line, "- \(self.isRepeat)")
                 
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
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
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
//                    self.subscribePlayer(self.avPlayer)
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
    
    func addAllViedeosToPlayer() {
        for i in 1...8 {
            guard let url = Bundle.main.url(forResource: "v\(i)", withExtension: "mp4") else { return }
            
            let asset = AVURLAsset(url: url)
            
            let item = AVPlayerItem(asset: asset)
            currentItemsForPlayer.append(item)
        }
        
        playItems(with: currentItemsForPlayer)
    }
    

    // MARK: - Add Pinch Gesture To Zoom in/out the Video
    
    private func addPinchGesturer() {
        pinchGesture.rx.event
            .subscribe(onNext: { (gesture) in
                guard gesture.view != nil else { return }
                
                if gesture.state == .began || gesture.state == .changed {
                    guard let view = gesture.view else { return }
                    
                    view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
                    gesture.scale = 1
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Add Double Tap Gesture To Set Zoom Status to Default
    
    private func addDoubleTapGesture() {
        tapGesture.rx.event
            .subscribe(onNext: { (gesture) in
                gesture.numberOfTapsRequired = 2
                guard gesture.view != nil else { return }
                
                if let view = gesture.view {
                    UIView.animate(withDuration: 0.3) {
                        view.transform = .identity
                    }
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Control Zoom In / Out
    
    /// isZoom속성에 따라 화면을 확대/축소합니다.
    ///
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
    
    
    // MARK: - Play Items
    
    private func playItems(with items: [AVPlayerItem]) {
        guard let currentItemIndex = currentItemIndex else { return }
        
        for i in 0..<items.count {
            
            if i != currentItemIndex {
                avPlayer.replaceCurrentItem(with: currentItemsForPlayer[currentItemIndex])
                avPlayer.play()
            }
        }
    }
    
    
    // MARK: - Play Next Video Item
    
    func playNextVideo(_ player: AVPlayer) {
        guard var currentItemIndex = currentItemIndex else { return }
        
        if currentItemIndex + 1 < currentItemsForPlayer.count {
            currentItemIndex += 1
            avPlayer.replaceCurrentItem(with: currentItemsForPlayer[currentItemIndex])
            avPlayer.currentItem?.seek(to: .zero, completionHandler: nil)
            avPlayer.play()
        } else {
            alertToPlayer(title: "Alert",
                          message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well")
            .subscribe(onNext: { [weak self] (actionType) in
                guard let self = self else { return }
                
                switch actionType {
                case .ok:
                    self.addAllViedeosToPlayer()
                case .cancel:
                    self.updateUIForPlayerItemDefaultState()
                }
            })
            .disposed(by: rx.disposeBag)
        }
    }
    
    
    // MARK: - Play Previos Video Item
    
    private func playPreviousVideo(_ player: AVPlayer) {
        guard var currentItemIndex = currentItemIndex else { return }
        
        if currentItemIndex - 1 >= 0 {
            currentItemIndex -= 1
            avPlayer.replaceCurrentItem(with: currentItemsForPlayer[currentItemIndex])
            avPlayer.currentItem?.seek(to: .zero, completionHandler: nil)
            avPlayer.play()
        } else {
            alertToPlayer(title: "Alert",
                          message: "There is no item to play previous item. Current item is the first item.")
            .subscribe(onNext: { (actionType) in
                switch actionType {
                default:
                    break
                }
            })
            .disposed(by: rx.disposeBag)
        }
    }
}

