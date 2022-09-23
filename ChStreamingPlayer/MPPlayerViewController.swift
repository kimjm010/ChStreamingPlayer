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
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    
    // MARK: - Vars
    
    private let videoPlayer = StreamingVideoPlayer()
    
    
    // MARK: - IBActions
    
    /// Control Play
    @IBAction func playButtonTapped() {
        guard let path = Bundle.main.path(forResource: "v1", ofType: "mp4"),
        let url = URL(string: path) else {
         print(#function, #file, #line, "Error Occurred when Parsing Url")
            return
        }
        
        videoPlayer.play(url: url)
    }
    
    
    /// Control Pause
    @IBAction func pauseButtonTapped() {
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
        initializeData()
    }
    
    
    // MARK: - Initialize Data
    
    private func initializeData() {
        backgroundImageView.isHidden = true
    }
    
    
    // MARK: - Add Streaming Video Player to Video View
    
    private func setupVideoPlayer() {
        videoPlayer.add(to: playerView)
    }
    
    
    // MARK: - Update UI
    
    private func updateUI() {
        videoPlayer.updateStatus { [weak self] (isPlaying) in
            guard let self = self else { return }
            
            self.backgroundImageView.isHidden = isPlaying ? true : false
            self.backgroundImageView.isHighlighted = isPlaying ? false : true
        }
    }
}

