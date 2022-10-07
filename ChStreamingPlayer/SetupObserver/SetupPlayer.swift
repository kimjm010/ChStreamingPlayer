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
        timeControlStatusDisposable = nil
        
        timeControlStatusDisposable = player.rx.timeControlStatus.asDriver(onErrorJustReturn: .playing)
            .map { $0 == .playing ? UIImage(systemName: MPPlayerViewController.pauseImage) : UIImage(systemName: MPPlayerViewController.playImage) }
            .drive(playPauseButton.rx.image())
        
        
        // player 아이템이 없는 경우 사용자에게 알림 표시
        player.rx.timeControlStatus
            .map { $0 == .waitingToPlayAtSpecifiedRate }
            .subscribe(onNext: { [unowned self] _ in
                player.rx.items()
                    .filter { $0.count == 0 }
                    .flatMap { [unowned self] _ in self.alertAddItemsToPlayer(title: "Alert",
                                                                              message: "There are no items. Do you wnat to add new videos? If you want, please press 'Ok'.\n You can add video list by presing 'play' button as well") }
                    .subscribe(onNext: { (actionType) in
                        switch actionType {
                        case .ok:
                            self.addAllViedeosToPlayer()
                        case .cancel:
                            self.updateUIForPlayerItemDefaultState()
                        }
                    })
                    .disposed(by: self.rx.disposeBag)
            })
            .disposed(by: rx.disposeBag)
        
        
        // 현재 재생시간 레이블 / slider 변경
        playbackPositionDisposable = nil
        
        playbackPositionDisposable = player.rx.playbackPosition(updateQueue: .main)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.timeSlider.value = $0
                self.startTimeLabel.text = self.createTimeString(time: $0)
            })
    }
}
