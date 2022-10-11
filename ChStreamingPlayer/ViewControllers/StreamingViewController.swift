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
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var topMenuStackView: UIStackView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var pipModeButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var adButton: UIButton!
    
    
    // MARK: - Vars
    
    let videoPlayer = StreamingVideoPlayer()
    static let playImage = "play.fill"
    static let pauseImage = "pause.fill"
    let avPlayer = AVPlayer()
    var isTapped = true
    var isRotated = false
    
    lazy var orientationObservable = Observable.just(UIDevice.orientationDidChangeNotification)

    static let urlStr = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        avPlayer.volume = 0.0
        #endif
        
        setupPlayer()
        initializeData()
        addToView()
        
        subscribePlayer(avPlayer)
        addTapGesture()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        avPlayer.pause()
    }
    
    
    // MARK: - Setup Player
    
    private func setupPlayer() {
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
        pipModeButton.setTitle("", for: .normal)
        rotateButton.setTitle("", for: .normal)
        shareButton.setTitle("", for: .normal)
        menuButton.setTitle("", for: .normal)
        adButton.setTitle("", for: .normal)
        
        // Set Button Hidden Property
        updateUI()
    }
    
    
    // MARK: - Add Player View To View
    
    private func addToView() {
        view.addSubview(playerView)
        
        #warning("Todo: - 제약 확인할 것")
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    
    // MARK: - Add Tap Gesture
    
    private func addTapGesture() {
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] (gesture) in
                guard let self = self else { return }
                
                self.isTapped.toggle()
                
                #warning("Todo: - 일정 시간 지나면 다시 안보이도록 설정할 것")
                UIView.animate(withDuration: 0.3) {
                    self.updateUI(self.isTapped)
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    // MARK: - Update UI
    
    private func updateUI(_ isTapped: Bool = true) {
        topMenuStackView.isHidden = isTapped
        pipModeButton.isHidden = topMenuStackView.isHidden
        adButton.isHidden = topMenuStackView.isHidden
        rotateButton.isHidden = topMenuStackView.isHidden
        playPauseButton.isHidden = topMenuStackView.isHidden
    }
}

