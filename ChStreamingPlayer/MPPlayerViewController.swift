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
        guard let urlStr = Bundle.main.path(forResource: "1", ofType: "mp4"),
              let url = URL(string: urlStr) else {
            print(#function, #file, #line, "Error occurred when parsing Url")
            return
        }
        
        print(#function, #file, #line, "\(url)")
        videoPlayer.play(url: url)
    }
    
    
    /// Control Pause
    @IBAction func pauseButtonTapped() {
        
    }
    
    
    /// Control backward event
    @IBAction func backwardButtonTapped() {
        
    }
    
    
    /// Control forward event
    @IBAction func forwardButtonTapped() {
        
    }
    
    
    /// Turon on volume
    @IBAction func muteButtonTapped() {
        
    }
    
    
    /// Turon off(mute) volume
    @IBAction func turnVolumeButtonTapped() {
        
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

