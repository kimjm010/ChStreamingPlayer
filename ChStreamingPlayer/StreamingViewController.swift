//
//  MainViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import AVFoundation
import StreamingKit
import RxAudioVisual
import NSObject_Rx
import RxSwift
import AVKit


class StreamingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var turnOnVolumeButton: UIButton!
    
    
    // MARK: - Vars
    
    private let videoPlayer = StreamingVideoPlayer()
    
    private let avPlayer = AVPlayer()
    
    
    // MARK: - IBActions
    
    @IBAction func playButtonTapped() {
        let urlStr = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
        
        guard let url = URL(string: urlStr) else {
            return
        }
        let item = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: item)
        
//        videoPlayer.play(url: url)
    }
    
    
    @IBAction func pauseButtonTapped() {
        videoPlayer.pause()
    }
    
    
    @IBAction func muteButtonTapped() {
//        videoPlayer.muteVolume()
        
    }
    
    
    @IBAction func volUpButtonTapped() {
//        videoPlayer.turnOnVolume()
    }

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoPlayer()
        playVideo()
        
        muteButton.rx.tap
            .subscribe { [weak self] in
                guard let self = self else { return }
                print(#function, #file, #line, "\($0)")
                self.avPlayer.rx.muted
                    .subscribe {
                        if $0 {
                            self.videoPlayer.muteVolume()
                        } else {
                            self.videoPlayer.turnOnVolume()
                        }
                    }
                    .disposed(by: self.rx.disposeBag)
            }
            .disposed(by: rx.disposeBag)
        
        
        muteButton.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                print(#function, #file, #line, "\(self.avPlayer.isMuted)")
                if !self.avPlayer.isMuted {
                    self.videoPlayer.muteVolume()
                }
            })
            .disposed(by: rx.disposeBag)
        
        turnOnVolumeButton.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                
            })
        
                
                
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        videoPlayer.pause()
    }
    
    
    // MARK: - Add Streaming Video Player View to Video View
    
    private func setupVideoPlayer() {
        videoPlayer.add(to: videoView)
    }
    
    
    // MARK: - Play Video
    
    private func playVideo() {
        let urlStr = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
        
        guard let url = URL(string: urlStr) else {
            print(#function, #file, #line, "Error Occurred when Parsing Url")
            return
        }
        
        videoPlayer.play(url: url)
    }
}

