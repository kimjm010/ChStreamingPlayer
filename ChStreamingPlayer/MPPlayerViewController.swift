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
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    
    // MARK: - Vars
    
    private let videoPlayer = StreamingVideoPlayer()
    
    
    // MARK: - IBActions
    
    /// Control Play
    @IBAction func playButtonTapped() {
        
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
    }
    
    
    // MARK: - Add Streaming Video Player to Video View
    
    private func setupVideoPlayer() {
        videoPlayer.add(to: videoView)
    }
}
