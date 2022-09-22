//
//  MainViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import UIKit
import StreamingKit


class MainViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var videoView: UIView!
    
    
    // MARK: - Vars
    
    private let videoPlayer = StreamingVideoPlayer()
    
    
    // MARK: - IBActions
    
    @IBAction func playButtonTapped() {
        guard let text = textField.text,
              let url = URL(string: text) else {
            print(#function, #file, #line, "Error Parsing Url")
            return
        }
        
        videoPlayer.play(url: url)
    }
    
    
    @IBAction func pauseButtonTapped() {
        videoPlayer.pause()
    }
    
    
    @IBAction func clearButtonTapped() {
        textField.text = nil
        videoPlayer.pause()
    }
    
    
    @IBAction func muteButtonTapped() {
        videoPlayer.muteVolume()
    }
    
    
    @IBAction func volUpButtonTapped() {
        videoPlayer.turnOnVolume()
    }
    
    
    @IBAction func rewindButtonTapped() {
        videoPlayer.moveToBackward()
    }
    
    
    @IBAction func forwardButtonTapped() {
        videoPlayer.moveToForward()
    }

    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoPlayer()
    }
    
    
    /// videoView에 Streaming Video Player View를 추가
    private func setupVideoPlayer() {
        videoPlayer.add(to: videoView)
    }
}

