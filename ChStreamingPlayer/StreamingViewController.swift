//
//  MainViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import UIKit
import StreamingKit


class StreamingViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var videoView: UIView!
    
    
    // MARK: - Vars
    
    private let videoPlayer = StreamingVideoPlayer()
    
    
    // MARK: - IBActions
    
    @IBAction func playButtonTapped() {
        print(#function)
        videoPlayer.resume()
    }
    
    
    @IBAction func pauseButtonTapped() {
        videoPlayer.pause()
    }
    
    
    @IBAction func muteButtonTapped() {
        videoPlayer.muteVolume()
    }
    
    
    @IBAction func volUpButtonTapped() {
        videoPlayer.turnOnVolume()
    }

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoPlayer()
        playVideo()
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

