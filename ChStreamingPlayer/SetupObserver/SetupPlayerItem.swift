//
//  SetupPlayerItem.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/28/22.
//

import Foundation
import AVFoundation
import NSObject_Rx
import ProgressHUD
import RxSwift
import UIKit



extension MPPlayerViewController {
    
    
    /// AVQueuePlayer의 currentItem으로 AVPlayer의 기능을 수행
    ///
    /// - Parameter currentItem: AVQueuePlayer의 현재 아이템
    func subscribeCurrentItem(_ currentItem: AVPlayerItem) {
        // #3 #5 #6 #7 
        presentationDisposable = nil
        
        // 미디어 아이템에 따라 portrait / landscape모드 레이블 표시
        presentationDisposable = currentItem.rx.presentation()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.videoModeLabel.text = $0.width > $0.height ? "Landscape Mode" : "Portrait Mode"
                
                #warning("Todo: - #1, #3 영상은 landscape mode로 돌아갔다 되돌아오는 문제 해결 필요")
                /// **가로세로모드 자동 변경 코드**
                /*
                 let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                 windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: $0.width > $0.height ? .landscape : .portrait))
                 */
            })
        
        canPlayFastForwardDisposable = nil
        
        // 빨리감기 가능 여부 확인
        canPlayFastForwardDisposable = currentItem.rx.canPlayFastForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.forwardButton.isEnabled = $0
                self.nextVideoButton.isEnabled = $0
            })
        
        canPlayReverseDisposable = nil
        
        // 되감기 가능 여부 확인
        canPlayReverseDisposable = currentItem.rx.canPlayReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.previousVideoButton.isEnabled = $0
            })
        
        canStepForwardDisposable = nil
        
        // 앞으로 이동 가능 여부 확인
        canStepForwardDisposable = currentItem.rx.canStepForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveForwardButton.isEnabled = $0
            })
        
        canStepBackwardDisposable = nil
        
        // 뒤로 이동 가능 여부 확인
        canStepBackwardDisposable = currentItem.rx.canStepBackward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveBackButton.isEnabled = $0
            })
        
        canPlayFastReverseDisposable = nil
        
        // 뒤로 이동 가능 여부 확인
        canPlayFastReverseDisposable = currentItem.rx.canPlayFastReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.repeatButton.isEnabled = $0
            })
        
        statusDisposable = nil
        
        // playerItem Status에 따라 버튼 UI 변경
        statusDisposable = currentItem.rx.status()
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
        
        durationDisposable = nil
        
        // 현재 미디어 아이템의 남은시간을 업데이트
        durationDisposable = currentItem.rx.duration
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.durationLabel.text = self.createTimeString(time: Float($0.seconds))
            })
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
        durationLabel.isEnabled = true
    }
    
    
    /// playerItem의 기본 UI
    func updateUIForPlayerItemDefaultState() {
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


