//
//  SetupPlayerItem.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/28/22.
//

import Foundation
import AVFoundation
import RxSwift
import NSObject_Rx
import ProgressHUD



extension MPPlayerViewController {
    
    func subscribeCurrentItem(_ currentItem: AVPlayerItem) {
        
        // 빨리감기 가능 여부 확인
        currentItem.rx.canPlayFastForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.forwardButton.isEnabled = $0
                self.nextVideoButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        // 되감기 가능 여부 확인
        currentItem.rx.canPlayReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.previousVideoButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        // 앞으로 이동 가능 여부 확인
        currentItem.rx.canStepForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveForwardButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        // 뒤로 이동 가능 여부 확인
        currentItem.rx.canStepBackward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveBackButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        // 뒤로 이동 가능 여부 확인
        currentItem.rx.canPlayFastReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.repeatButton.isEnabled = $0
            })
            .disposed(by: rx.disposeBag)
        
        /// ** CurrentSize Observer -> Swift**
        // 미디어 아이템에 따라 portrait / landscape모드 레이블 표시
        currentItem.rx.presentation()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.videoModeLabel.text = $0.width > $0.height ? "Landscape Mode" : "Portrait Mode"
            })
            .disposed(by: rx.disposeBag)
        
        
        // playerItem Status에 따라 버튼 UI 변경
        currentItem.rx.status()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                switch $0 {
                case .failed:
                    self.updateUIForPlayerItemFailedState()
                case .readyToPlay:
                    self.updateUIForPlayerItemReadyToPlayState()
                default:
                    self.updateUIForPlayerItemDefaultState()
                }
            })
            .disposed(by: rx.disposeBag)
        
        // 현재 미디어 아이템의 남은시간을 업데이트
        currentItem.rx.duration
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.durationLabel.text = self.createTimeString(time: Float($0.seconds))
            })
            .disposed(by: rx.disposeBag)
        
        /*
         //player의 현재 시각이 처음 시각과 같은 경우 재생시간 맨 끝으로 이동
         if avPlayer.currentItem?.currentTime() == .zero {
         if let itemDuration = avPlayer.currentItem?.duration {
         avPlayer.currentItem?.seek(to: itemDuration, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
         }
         }
         
         avPlayer.rate = max(avPlayer.rate - 2.0, -2.0)
         */
    }
    
    
    // MARK: - Update UI based on Player Item Status
    
    /// playerItem이 fail인 경우 표시할 UI
    private func updateUIForPlayerItemFailedState() {
        playPauseButton.isEnabled = false
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackButton.isEnabled = false
        moveForwardButton.isEnabled = false
        nextVideoButton.isEnabled = false
        previousVideoButton.isEnabled = false
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
        ProgressHUD.showFailed("Error ocurred when playing video. Please try again later.")
    }
    
    
    /// playerItem이 readyToPlay인 경우 표시할 UI
    private func updateUIForPlayerItemReadyToPlayState() {
        guard let currentItem = avPlayer.currentItem else { return }
        
        playPauseButton.isEnabled = true
        moveBackButton.isEnabled = true
        moveForwardButton.isEnabled = true
        nextVideoButton.isEnabled = true
        previousVideoButton.isEnabled = true
        forwardButton.isEnabled = true
        backwardButton.isEnabled = true
        
        let newDurationSeconds = Float(currentItem.duration.seconds)
        let currentTimes = Float(CMTimeGetSeconds(avPlayer.currentTime()))
        
        timeSlider.maximumValue = newDurationSeconds
        timeSlider.value = currentTimes
        timeSlider.isEnabled = true
        startTimeLabel.isEnabled = true
        startTimeLabel.text = createTimeString(time: currentTimes)
        durationLabel.isEnabled = true
        durationLabel.text = createTimeString(time: newDurationSeconds)
    }
    
    
    /// playerItem의 기본 UI
    private func updateUIForPlayerItemDefaultState() {
        playPauseButton.isEnabled = false
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackButton.isEnabled = false
        moveForwardButton.isEnabled = false
        nextVideoButton.isEnabled = false
        previousVideoButton.isEnabled = false
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
    }
}


