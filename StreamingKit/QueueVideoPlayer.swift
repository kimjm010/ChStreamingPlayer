//
//  QueueVideoPlayer.swift
//  StreamingKit
//
//  Created by Chris Kim on 9/23/22.
//

import AVKit
import AVFoundation


public class QueueVideoPlayer {
    public init() { }
    
    
    // MARK: -  Vars
    
    private let playerViewController = AVPlayerViewController()
    
    private let avPlayer = AVQueuePlayer()
    
    private lazy var playerView: UIView = {
        let view = playerViewController.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var currentTime: Float64?
    
    private let playImage = UIImage(named: "play_background")
    
    private let pauseImage = UIImage(named: "pause_Background")
    
    private var videoList = [
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
    ]
    
    private var token: NSKeyValueObservation?
    
    private var allUrls = [URL]()
    
    
    init(urls: [URL]) {
        allUrls = urls
        
        
    }
    
    
    // MARK: - Add PlayerView to SuperView
    
    public func add(to view: UIView) {
        view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    
    // MARK: - Set Background Image
    
    private func setBackgroundImage(name: String) {
        print(#function)
        
        UIGraphicsBeginImageContext(playerView.frame.size)
        UIImage(named: name)?.draw(in: playerView.bounds)
        UIGraphicsEndImageContext()
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
        currentTime = CMTimeGetSeconds(avPlayer.currentTime())
    }
    
    
    public func resume() {
        guard let currentTime = currentTime else {
            
            return
        }
        let setTime: CMTime = CMTimeMake(value: Int64(currentTime * 1000 as Float64), timescale: 1000)
        avPlayer.seek(to: setTime, toleranceBefore: .zero, toleranceAfter: .zero)
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
    
    
    // MARK: - Update Current Time
    
    public func updateCurrentTime() {
        currentTime = CMTimeGetSeconds(avPlayer.currentTime())
    }
    
    
    // MARK: - Parse UrlStr to Url
    
    private func addAllVideosToPlayer() {
        for i in 0...4 {
            guard let path = Bundle.main.path(forResource: "v\(i)", ofType: "mp4"),
                  let url = URL(string: path) else { return }
            
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            avPlayer.insert(item, after: avPlayer.items().last)
        }
    }
    
    
    // ======================================================================================
    
    // MARK: - Key-Value Observing
    
    func setupPlayerObservers() {
        
    }
}
