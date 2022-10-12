//
//  SetupPlayer.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/10/22.
//

import AVFoundation
import NSObject_Rx
import Foundation
import RxCocoa
import RxSwift


extension StreamingViewController {
    
    func subscribePlayer(_ player: AVPlayer) {
        
        // 재생, 일시정지 이미지 변경
        player.rx.timeControlStatus.asDriver(onErrorJustReturn: .playing)
                .map { $0 == .playing ? UIImage(systemName: StreamingViewController.pauseImage) : UIImage(systemName: StreamingViewController.playImage) }
                .drive(playPauseButton.rx.image(for: .normal))
                .disposed(by: rx.disposeBag)

    
        #warning("Todo: - 일시정지가 안되네")
        // 재생, 일시정지
        playPauseButton.rx.tap
            .flatMap { [unowned self] in self.avPlayer.rx.timeControlStatus }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                print(#fileID, #function, #line, "- \($0)")
                
                switch $0 {
                case .paused:
                    self.avPlayer.play()
                case .waitingToPlayAtSpecifiedRate:
                    print(#fileID, #function, #line, "- ")
                case .playing:
                    self.avPlayer.rate = 0.0
                default:
                    print(#fileID, #function, #line, "- ")
                }
            })
            .disposed(by: rx.disposeBag)
        
        
        // 공유 기능
        shareButton.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                guard let url = URL(string: StreamingViewController.urlStr) else { return }
                
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                
                self.present(activityVC, animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        // display Setting View Controller
        menuButton.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                let settingVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
                settingVC.avPlayer = self.avPlayer
                
                self.tabBarController?.modalPresentationStyle = .fullScreen
                self.tabBarController?.present(settingVC, animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        // rotate the device's orientation mode
        rotateButton.rx.tap
            .flatMap { [unowned self] in self.orientationObservable }
            .subscribe(onNext: { _ in
                self.isRotated.toggle()
                self.rotateDevice(self.isRotated)
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    
    // MARK: - Rotate Device
    
    /// Rotating Device
    ///
    /// - Parameter isPortrait: check the device's orientation mode
    private func rotateDevice(_ isPortrait: Bool = true) {
        if isPortrait {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            if #available(iOS 16.0, *) {
                self.updateConstraints()
                tabBarController?.tabBar.isHidden = true
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            } else {
                self.updateConstraints()
                tabBarController?.tabBar.isHidden = true
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        } else {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            if #available(iOS 16.0, *) {
                tabBarController?.tabBar.isHidden = false
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            } else {
                tabBarController?.tabBar.isHidden = false
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }
    }
    
    
    // MARK: - Update Constraints
    
    private func updateConstraints(_ isPortrait: Bool = true) {
        if isPortrait {
            playerView.translatesAutoresizingMaskIntoConstraints = false
            playerViewHeightAnchorConstant.constant = 0.0
            NSLayoutConstraint.activate([
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            #warning("Todo: - 다시 돌렸을 때 기존 화면으로 되돌리기")
            playerViewHeightAnchorConstant.constant = 350.0
        }
    }
}
