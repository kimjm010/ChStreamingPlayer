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
    @IBOutlet weak var playerViewHeightAnchorConstant: NSLayoutConstraint!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var topMenuStackView: UIStackView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var displayStackView: UIStackView!
    
    
    // MARK: - Vars
    
    let videoPlayer = StreamingVideoPlayer()
    static let playImage = "play.fill"
    static let pauseImage = "pause.fill"
    let avPlayer = AVPlayer()
    var isRotated = false
    
    lazy var orientationObservable = Observable.just(UIDevice.orientationDidChangeNotification)
    var pictureInPictureController: AVPictureInPictureController?

    static let urlStr = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPlayer()
        initializeData()
        addTapGesture()
        setTapBarAppearanceAsDefault()
        subscribePlayer(avPlayer)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
    }
    
    
    // MARK: - Setup Player
    
    func setupPlayer() {
        guard let url = URL(string: StreamingViewController.urlStr) else { return }
        
        let item = AVPlayerItem(url: url)
        avPlayer.replaceCurrentItem(with: item)
        playerView.player = avPlayer
        avPlayer.play()
    }
    
    
    // MARK: -  Initialize Data
    
    private func initializeData() {
        
        // Set Button Title
        playPauseButton.setTitle("", for: .normal)
        rotateButton.setTitle("", for: .normal)
        shareButton.setTitle("", for: .normal)
        menuButton.setTitle("", for: .normal)
        
        controlsView.alpha = 0.0
    }
    
    
    // MARK: - Add Tap Gesture
    
    private func addTapGesture() {
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] (gesture) in
                guard let self = self else { return }
                
                #warning("Todo: - 일정 시간 지나면 다시 안보이도록 설정할 것")
                
                if self.controlsView.alpha == 0.0 {
                    self.showControls()
                } else {
                    self.hideControls()
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Update UI
    
    private func showControls() {
        controlsView.alpha = 0.0
        
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            self.controlsView.alpha = 1.0
        }
    }
    
    
    private func hideControls() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }
            self.controlsView.alpha = 0.0
        }
    }
}
