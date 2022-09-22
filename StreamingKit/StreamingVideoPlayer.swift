//
//  File.swift
//  StreamingKit
//
//  Created by Chris Kim on 9/22/22.
//

import AVKit
import AVFoundation


public class StreamingVideoPlayer {
    
    public init() { }
    
    // MARK: - Vars
    
    private let playerViewController = AVPlayerViewController()
    
    private let avPlayer = AVPlayer()
    
    private lazy var playerView: UIView = {
        let view = playerViewController.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var isPlaying: Bool {
        return avPlayer.rate == 1.0 ? true : false
    }

    
    // MARK: - Public Interface
    
    /// superView에 playerViewf를 추가하기 위한 메소드
    public func add(to view: UIView) {
        view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Control Play
    
    public func play(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        avPlayer.replaceCurrentItem(with: playerItem)
        playerViewController.player = avPlayer
        playerViewController.player?.play()
    }
    
    
    public func pause() {
        avPlayer.pause()
    }
    
    
    // MARK: - Move to Forward and Backward
    
    public func moveToBackward() {
        let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let newTime = currentTime - 10
        let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    
    public func moveToForward() {
        let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
        let newTime = currentTime + 10
        let setTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    
    // MARK: - Control Volume
    
    public func turnOnVolume() {
        avPlayer.volume = 1.0
    }
    
    
    public func muteVolume() {
        avPlayer.volume = 0.0
    }
    
    
    // MARK: - Update Status
    
    public func updateStatus(completion: (Bool) -> Void) {
        if isPlaying {
            avPlayer.pause()
            completion(true)
        } else {
            avPlayer.play()
            completion(false)
        }
    }
}
