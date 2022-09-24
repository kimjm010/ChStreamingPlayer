//
//  MPPlayerViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import Foundation
import AVKit
import AVFoundation


class MPPlayerViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    
    // MARK: - Vars
    
    private let avPlayer = AVPlayer()
    
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
    
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    static let playButtonImageName = "play.fill"
    
    static let pauseButtonImageName = "play.fill"
    
    
    // MARK: - IBActions
    
    @IBAction func togglePlay(_ sender: Any) {
        print(#function, #file, #line, "재생 버튼 누름")
        
        switch avPlayer.timeControlStatus {
        case .playing:
            // player 가 playing중인 경우 멈춤
            avPlayer.pause()
        
        case .paused:
            let currentItem = avPlayer.currentItem
            if currentItem?.currentTime() == currentItem?.duration {
                currentItem?.seek(to: .zero, completionHandler: nil)
                avPlayer.play()
            }
            
        default:
            avPlayer.pause()
        }
    }
    
    
    @IBAction func moveBack(_ sender: Any) {
        // player의 현재 시각이 처음 시각과 같은 경우 재생시간 맨 끝으로 이동
        if avPlayer.currentItem?.currentTime() == .zero {
            if let itemDuration = avPlayer.currentItem?.duration {
                avPlayer.currentItem?.seek(to: itemDuration, completionHandler: nil)
            }
        }
        
        avPlayer.rate = max(avPlayer.rate - 2.0, 2.0)
    }
    
    
    @IBAction func moveForward(_ sender: Any) {
        // player의 현재 시각이 끝 시각과 같은 경우 재생시간 처음으로 이동
        if avPlayer.currentItem?.currentTime() == avPlayer.currentItem?.duration {
            avPlayer.currentItem?.seek(to: .zero, completionHandler: nil)
        }
        
        avPlayer.rate = min(avPlayer.rate + 2.0, 2.0)
    }
    
    
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
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
        if let timeObservetToken = timeObservetToken {
            avPlayer.removeTimeObserver(timeObservetToken)
            self.timeObservetToken = nil
        }
    }
    
    func loadPropertyValues(forAsset newAsset: AVURLAsset) {
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
    
    private func validateValues(forKeys keys: [String], forAsset newAsset: AVAsset) -> Bool {
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
            /*
             You can't play the asset. Either the asset can't initialize a
             player item, or it contains protected content.
             */
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
        playerTimeControlStatusObserver = avPlayer.observe(\AVPlayer.timeControlStatus, options: [.initial, .new]) { [weak self] (_, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.setPlayPauseButtonImage()
            }
        }
        
        
        // Create a periodic observer to update movie player time slider
        let interval = CMTime(value: 1, timescale: 2)
        timeObservetToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] (time) in
            guard let self = self else { return }
            
            let timeElapsed = Float(time.seconds)
            self.timeSlider.value = timeElapsed
            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
        })
        
        
        #warning("Todo: - 10초 앞으로 이동하도록 변경할 것")
        // Create an observer on the player's 'canPlayFastForward' property
        playerItemFastForwardObserver = avPlayer.observe(\AVPlayer.currentItem?.canPlayFastForward, options: [.initial, .new], changeHandler: { [weak self] (player, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.forwardButton.isEnabled = player.currentItem?.canPlayFastForward ?? false
            }
        })
        
        
        playerItemReverseObserver = avPlayer.observe(\AVPlayer.currentItem?.canPlayReverse,
                                                   options: [.new, .initial]) { [unowned self] player, _ in
            DispatchQueue.main.async {
                self.rewindButton.isEnabled = player.currentItem?.canPlayReverse ?? false
            }
        }
        
        #warning("Todo: - 10초 뒤로 이동하도록 변경할 것")
        playerItemFastReverseObserver = avPlayer.observe(\AVPlayer.currentItem?.canPlayFastReverse,
                                                       options: [.new, .initial]) { [unowned self] player, _ in
            DispatchQueue.main.async {
                self.rewindButton.isEnabled = player.currentItem?.canPlayFastReverse ?? false
            }
        }
        
        playerItemStatusObserver = avPlayer.observe(\AVPlayer.currentItem?.status, options: [.new, .initial]) { [unowned self] _, _ in
            DispatchQueue.main.async {
                /*
                 Configure the user interface elements for playback when the
                 player item's `status` changes to `readyToPlay`.
                 */
                self.updateUIForPlayerItemStatus()
            }
        }
    }
    
    
    // MARK: - Adjust Play/Pause Button Image
    
    private func setPlayPauseButtonImage() {
        var buttonImage: UIImage?
        
        switch avPlayer.timeControlStatus {
        case .playing:
            buttonImage = UIImage(systemName: MPPlayerViewController.pauseButtonImageName)
        case .paused, .waitingToPlayAtSpecifiedRate:
            buttonImage = UIImage(systemName: MPPlayerViewController.playButtonImageName)
        default:
            buttonImage = UIImage(systemName: MPPlayerViewController.playButtonImageName)
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
            #warning("Todo: - Progress HUD 로 에러 메세지 전달하기")
        
        case .readyToPlay:
            playPauseButton.isEnabled = true
            
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
        }
    }
    
    
    // MARK: - Convert Time to String
    
    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    
    // MARK: - Error Handling
    func handleErrorWithMessage(_ message: String, error: Error? = nil) {
        if let err = error {
            print("Error occurred with message: \(message), error: \(err).")
        }
        let alertTitle = NSLocalizedString("Error", comment: "Alert title for errors")
        
        let alert = UIAlertController(title: alertTitle, message: message,
                                      preferredStyle: UIAlertController.Style.alert)
        let alertActionTitle = NSLocalizedString("OK", comment: "OK on error alert")
        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
}

