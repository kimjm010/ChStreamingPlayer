//
//  MPPlayerViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import Foundation
import AVKit
import AVFoundation
import ProgressHUD


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
    
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    private var playerCurrentItem: NSKeyValueObservation?
    
    var tapGesture = UITapGestureRecognizer()
    
    var isRepeat = false
    
    
    // MARK: - IBActions
    
    /// Play Video
    @IBAction func togglePlay(_ sender: Any) {
        
        if avPlayer.items().count == 0 {
            alertAddItemsToPlayer(title: "Alert", message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in
                
                guard let self = self else { return }
                self.addAllViedeosToPlayer()
            }
        }
        
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
    
    
    /// Play Fast Backward
    @IBAction func moveFastBackward(_ sender: Any) {
        
            // player의 현재 시각이 처음 시각과 같은 경우 재생시간 맨 끝으로 이동
            if avPlayer.currentItem?.currentTime() == .zero {
                if let itemDuration = avPlayer.currentItem?.duration {
                    avPlayer.currentItem?.seek(to: itemDuration, completionHandler: nil)
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
                alertAddItemsToPlayer(title: "Alert", message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in
                    
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
            
            avPlayer.seek(to: .zero)
        }
        
        let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let newTime = currentTime - 10
        let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    
    /// 다음 재생항목으로 이동
    @IBAction func nextVideo() {
        if avPlayer.items().count > 1 {
            avPlayer.advanceToNextItem()
        } else {
            alertAddItemsToPlayer(title: "Alert", message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { [weak self] _ in
                guard let self = self else { return }
                
                self.addAllViedeosToPlayer()
            }
        }
    }
    
    
    /// 이전 재생항목으로 이동
    @IBAction func previousVideo() {
        if avPlayer.currentItem?.currentTime() == .zero {
            if avPlayer.currentItem != avPlayer.items().first {
                
            }
        } else {
            avPlayer.seek(to: .zero)
        }
    }
    
    
    /// 반복재생
    @IBAction func repeatVideoPlay(_ sender: Any) {
        isRepeat.toggle()
        
        if isRepeat {
            repeatButton.setImage(UIImage(systemName: "repeat.1"), for: .normal)
            guard let currentItem = avPlayer.currentItem else { return }
            playerLooper = AVPlayerLooper(player: avPlayer, templateItem: currentItem)
            avPlayer.play()
        } else {
            repeatButton.setImage(UIImage(systemName: "repeat"), for: .normal)
            avPlayer.play()
        }
    }
    
    
    /// Change Slider value
    @IBAction func timseSliderDidChange(_ sender: UISlider) {
        let newTime = CMTime(seconds: Double(sender.value), preferredTimescale: 600)
        avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = Bundle.main.url(forResource: "v1", withExtension: "mp4") else { return }
        
        let asset = AVURLAsset(url: url)
        loadPropertyValues(forAsset: asset)
        
        addAllViedeosToPlayer()
        addPinchGesturer()
        
        playerView.playerLayer.videoGravity = .resizeAspect
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
                    self.avPlayer.replaceCurrentItem(with: AVPlayerItem(asset: newAsset))
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
        
        // Create observer to toggle play/pause button
        playerTimeControlStatusObserver = avPlayer.observe(\AVQueuePlayer.timeControlStatus,
                                                            options: [.initial, .new]) { [weak self] (_, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.setPlayPauseButtonImage()
            }
        }
        
        
        // Create a periodic observer to update movie player time slider
        let interval = CMTime(value: 1, timescale: 1)
        timeObservetToken = avPlayer.addPeriodicTimeObserver(forInterval: interval,
                                                             queue: .main,
                                                             using: { [weak self] (time) in
            guard let self = self else { return }
            
            let timeElapsed = Float(time.seconds)
            self.timeSlider.value = timeElapsed
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
        })
        
        
        playerItemFastForwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayFastForward,
                                                          options: [.initial, .new],
                                                          changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.forwardButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
                self.nextVideoButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
            }
        })
        
        
        playerItemReverseObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayReverse,
                                                   options: [.new, .initial]) { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.backwardButton.isEnabled = player.currentItem?.canPlayReverse ?? false
                self.previousVideoButton.isEnabled = player.currentItem?.canPlayReverse ?? false
            }
        }
        
        
        playerItemMoveForwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canStepForward,
                                                          options: [.initial, .new],
                                                          changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.moveForwardButton.isEnabled = player.currentItem?.canStepForward ?? false
            }
        })
        
        
        playerItemMoveBackwardObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canStepBackward,
                                                          options: [.initial, .new],
                                                          changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.moveBackButton.isEnabled = player.currentItem?.canStepBackward ?? false
            }
        })
        
        
        playerItemFastReverseObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.canPlayFastReverse,
                                                       options: [.new, .initial]) { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.backwardButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
                self.repeatButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
            }
        }
        
        
        playerItemStatusObserver = avPlayer.observe(\AVQueuePlayer.currentItem?.status,
                                                     options: [.new, .initial]) { [weak self] (_, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.updateUIForPlayerItemStatus()
            }
        }
        
        
        playerCurrentItem = avPlayer.observe(\.currentItem, changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
          if player.items().count == 1 {
              self.alertAddItemsToPlayer(title: "Alert",
                                         message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.") { _ in
                  self.addAllViedeosToPlayer()
              }
          }
        })
        
    }
    
    
    // MARK: - Adjust Play/Pause Button Image
    
    private func setPlayPauseButtonImage() {
        var buttonImage: UIImage?
        
        switch avPlayer.timeControlStatus {
        case .playing:
            buttonImage = UIImage(systemName: "pause.fill")
        case .paused, .waitingToPlayAtSpecifiedRate:
            buttonImage = UIImage(systemName: "play.fill")
        default:
            buttonImage = UIImage(systemName: "play.fill")
        }
        
        guard let buttonImage = buttonImage else { return }
        playPauseButton.setImage(buttonImage, for: .normal)
    }

    
    // MARK: - Update UI based on Player Item Status
    
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
        for i in 1...5 {
            guard let url = Bundle.main.url(forResource: "v\(i)", withExtension: "mp4") else { return }
            
            let asset = AVURLAsset(url: url)
            
            let item = AVPlayerItem(asset: asset)
            
            avPlayer.insert(item, after: avPlayer.items().last)
        }
    }
    
    
    // MARK: - Add Pinch Gesture To Zoom in/out the Video
    
    private func addPinchGesturer() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        playerView.addGestureRecognizer(pinchGesture)
    }
    
    
    @objc
    private func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            guard let view = gestureRecognizer.view else { return }
            
            gestureRecognizer.view?.transform = view.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
        }
    }
    
    
    private func controlVideoPlayerZoomStatus() {
        
    }
    
}

