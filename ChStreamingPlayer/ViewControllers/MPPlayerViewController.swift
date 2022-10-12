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
    private static let finishRepeatImage = "repeat"
    private static let repeatImage = "repeat.1"
    var currentItemsForPlayer = [AVPlayerItem]()
    var currentItemIndex: Int?
    var avPlayer = AVPlayer()
    var isRepeat = false
    var isZoom = false
    
    
    // MARK: - Observable
    
    let isRepeatObservable = BehaviorSubject<Bool>(value: false)
    
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
    var didPlayToEndDisposable: Disposable? = nil
    
    
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
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 비디오 구성
        self.playerView.player = self.avPlayer
        addAllViedeosToPlayer()
        
        #if DEBUG
        avPlayer.replaceCurrentItem(with: currentItemsForPlayer[0])
        #endif
        
        initializeData()
        addPinchGesturer()
        addDoubleTapGesture()
        setTapBarAppearanceAsDefault()
        
        
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
        
        
        // 앞으로 10초 이동
        moveForwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: {
                
                let currentTime = CMTimeGetSeconds($0.currentTime())
                let newTime = currentTime + 10
                let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                $0.seek(to: setTime, completionHandler: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 10초 뒤로 이동
        moveBackwardButton.rx.tap
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
        
        
        // 빨리 감기
        forwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.avPlayer.rate = min(self.avPlayer.rate + 2.0, 2.0)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 빨리 되감기
        backwardButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
            .map { $0.value }
            .ignoreNil()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.avPlayer.rate = max(self.avPlayer.rate - 2.0, -2.0)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 다음 영상 재생
        nextVideoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.playNextVideo(self.avPlayer)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 이전 영상 재생
        previousVideoButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.playPreviousVideo(self.avPlayer)
            })
            .disposed(by: rx.disposeBag)
        
        
        // timeSlider 재생 위치 조정
        timeSlider.rx.value
            .map { BehaviorRelay<Float>(value: $0) }
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
        
        
        // 1번 반복재생
         repeatButton.rx.tap
             .flatMap { [unowned self] in self.avPlayer.rx.currentItem }
             .map { $0.value }
             .ignoreNil()
             .subscribe(onNext: { [weak self] (currentItem) in
                 guard let self = self else { return }

                 self.isRepeat.toggle()
                 self.isRepeatObservable.onNext(self.isRepeat)
                 
                 if self.isRepeat {
                     self.avPlayer.currentItem?.rx.didPlayToEnd
                         .subscribe(onNext: { _ in
                             self.avPlayer.replaceCurrentItem(with: currentItem)
                             self.avPlayer.currentItem?.seek(to: .zero, completionHandler: nil)
                             self.avPlayer.play()
                         })
                         .disposed(by: self.rx.disposeBag)
                 }
             })
             .disposed(by: rx.disposeBag)
        
        
        // 반복재생 버튼 클릭 시 이미지 변경
        isRepeatObservable
            .map { $0 ? UIImage(systemName: MPPlayerViewController.repeatImage) : UIImage(systemName: MPPlayerViewController.finishRepeatImage) }
            .bind(to: repeatButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
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
    
    
    // MARK: - Initialize Data
    
    private func initializeData() {
        backwardButton.setTitle("", for: .normal)
        forwardButton.setTitle("", for: .normal)
        playPauseButton.setTitle("", for: .normal)
        moveBackwardButton.setTitle("", for: .normal)
        moveForwardButton.setTitle("", for: .normal)
        nextVideoButton.setTitle("", for: .normal)
        previousVideoButton.setTitle("", for: .normal)
        repeatButton.setTitle("", for: .normal)
        controlZoomButton.setTitle("", for: .normal)
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

