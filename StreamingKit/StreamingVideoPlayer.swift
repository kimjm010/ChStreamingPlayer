//
//  File.swift
//  StreamingKit
//
//  Created by Chris Kim on 9/22/22.
//

import AVFoundation
import RxAudioVisual
import NSObject_Rx
import RxSwift
import AVKit


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
    
    var currentVolume: Float = 0.0

    
    // MARK: - Public Interface
    
    /// superView에 playerView를 추가하기 위한 메소드
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
        currentVolume = avPlayer.volume
        currentVolume += 0.1
        avPlayer.volume = currentVolume
    }
    
    
    public func muteVolume() {
        avPlayer.volume = 0.0
    }
}
