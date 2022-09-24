//
//  MPPlayerViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import UIKit
import StreamingKit


class MPPlayerViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    
    // MARK: - Vars
    
    private let videoPlayer = QueueVideoPlayer()
    
   
    
    
    // MARK: - IBActions
    
    /// Control Play
    @IBAction func playButtonTapped() {
        videoPlayer.resume()
    }
    
    
    /// Control Pause
    @IBAction func pauseButtonTapped() {
        videoPlayer.updateCurrentTime()
        videoPlayer.pause()
    }
    
    
    /// Control backward event
    @IBAction func backwardButtonTapped() {
        videoPlayer.moveToBackward()
    }
    
    
    /// Control forward event
    @IBAction func forwardButtonTapped() {
        videoPlayer.moveToForward()
    }
    
    
    /// Turon on volume
    @IBAction func muteButtonTapped() {
        videoPlayer.muteVolume()
    }
    
    
    /// Turon off(mute) volume
    @IBAction func turnVolumeButtonTapped() {
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
    
    
    // MARK: - Add Streaming Video Player to Video View
    
    private func setupVideoPlayer() {
        videoPlayer.add(to: playerView)
    }
    
    
    // MARK: - Play Video
    
    private func playVideo() {
        let urlStr = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        
        guard let url = URL(string: urlStr) else {
            print(#function, #file, #line, "Error Occurred when Parsing Url")
            return
        }
        
        videoPlayer.play(url: url)
    }
}

