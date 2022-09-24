//
//  PlayerView.swift
//  StreamingKit
//
//  Created by Chris Kim on 9/24/22.
//

import UIKit
import AVFoundation


class PlayerView: UIView {
    
    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
