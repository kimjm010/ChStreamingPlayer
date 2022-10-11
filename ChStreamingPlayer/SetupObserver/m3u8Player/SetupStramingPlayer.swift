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
                    #warning("Todo: - 일시정지가 안되네")
                    self.avPlayer.pause()
                default:
                    print(#fileID, #function, #line, "- ")
                }
            })
            .disposed(by: rx.disposeBag)
        
            
        
    }
    
}
