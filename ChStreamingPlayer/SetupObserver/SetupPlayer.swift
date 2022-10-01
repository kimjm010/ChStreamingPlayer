//
//  SetupPlayerObserver.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/28/22.
//

import Foundation
import AVFoundation
import RxAudioVisual
import NSObject_Rx
import RxSwift
import RxCocoa




extension MPPlayerViewController {
    
    private static let pauseImage = "pause.fill"
    
    private static let playImage = "play.fill"
    
    func subscribePlayer(_ player: AVPlayer) {
        
        // play/pause button 이미지 변경
        player.rx.timeControlStatus.asDriver(onErrorJustReturn: .playing)
            .map { $0 == .playing ? UIImage(systemName: MPPlayerViewController.pauseImage) : UIImage(systemName: MPPlayerViewController.playImage) }
            .drive(playPauseButton.rx.image())
            .disposed(by: rx.disposeBag)
        
        
        // 현재 재생시간 레이블 / slider 변경
        player.rx.playbackPosition(updateQueue: .main)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.timeSlider.value = $0
                self.startTimeLabel.text = self.createTimeString(time: $0)
            })
            .disposed(by: rx.disposeBag)
        
        // AVQueuePlayer의 미디어 아이템목록을 구독
        #warning("Todo: - 코드 처음에만 실행되고 그 뒤로는 실행되지 않아")
        player.rx.items()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if $0.count == 1 {
                    self.nextVideoButton.isEnabled = false
                }
            })
            .disposed(by: rx.disposeBag)
    }
}
