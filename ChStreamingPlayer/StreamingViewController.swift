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
        
        let urlStr = "https://livecloud.pstatic.net/navertv/lip2_kr/cnmss0068/UiOA18Ees6RVFEK2gWBdqh_3Z1isVvucV4lBZA4DnM96WrRiL8MF4j6ouvDO_g3k4OWk2r_1sxE0boeN/hdntl=exp=1663889041~acl=*%2FUiOA18Ees6RVFEK2gWBdqh_3Z1isVvucV4lBZA4DnM96WrRiL8MF4j6ouvDO_g3k4OWk2r_1sxE0boeN%2F*~data=hdntl~hmac=85b62c82e6ae7d02ccab57b4ffaa46e5ce8850f09ab3f89ba8aec7c8e551e543/chunklist_720.m3u8"
        
        guard let url = URL(string: urlStr) else {
            print(#function, #file, #line, "Error Parsing Url")
            return
        }
        
        videoPlayer.play(url: url)
    }
    
    
    @IBAction func pauseButtonTapped() {
        videoPlayer.pause()
    }
    
    
    @IBAction func clearButtonTapped() {
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

