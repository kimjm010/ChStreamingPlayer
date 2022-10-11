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
                
                switch $0 {
                case .paused:
                    self.avPlayer.play()
                case .waitingToPlayAtSpecifiedRate:
                    print(#fileID, #function, #line, "- ")
                case .playing:
                    self.avPlayer.pause()
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
        
        
        // 메뉴 화면 표시
        menuButton.rx.tap
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                let settingVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
                
                settingVC.avPlayer = self.avPlayer
                self.present(settingVC, animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
        
        
        rotateButton.rx.tap
            .flatMap { [unowned self] in self.orientationObservable }
            .subscribe(onNext: {
                self.isRotated.toggle()
                
                self.rotateDevice(self.isRotated)
                print(#fileID, #function, #line, "- \($0)")
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    
    private func rotateDevice(_ isPortrait: Bool = true) {
        if isPortrait {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            if #available(iOS 16.0, *) {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        } else {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            if #available(iOS 16.0, *) {
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }
    }
}
