//
//  MainViewController.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/22/22.
//

import UIKit
import AVKit
import AVFoundation


class MainViewController: UIViewController {
    
    var player = AVPlayer()
    var playerViewController = AVPlayerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightBarButton = UIBarButtonItem(title: "Play", style: .plain, target: self, action: #selector(openPlayer))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    
    
    @objc
    func openPlayer() {
        let videoUrlStr = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
        guard let videoUrl = URL(string: videoUrlStr) else { return }
        player = AVPlayer(url: videoUrl)
        playerViewController.player = player
        
        self.present(playerViewController, animated: true, completion: { [weak self] in
            guard let self = self else { return }
            self.player.play()
        })
    }
    
}
