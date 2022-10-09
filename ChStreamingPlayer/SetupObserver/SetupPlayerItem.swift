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
        
        presentationDisposable?.dispose()
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
        
        
        // 빨리감기 가능 여부 확인
        canPlayFastForwardDisposable?.dispose()
        canPlayFastForwardDisposable = nil
        
        canPlayFastForwardDisposable = currentItem.rx.canPlayFastForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.forwardButton.isEnabled = $0
                self.nextVideoButton.isEnabled = $0
            })
        
        
        // 되감기 가능 여부 확인
        canPlayReverseDisposable?.dispose()
        canPlayReverseDisposable = nil
        
        canPlayReverseDisposable = currentItem.rx.canPlayReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.previousVideoButton.isEnabled = $0
            })
        
        
        // 앞으로 이동 가능 여부 확인
        canPlayReverseDisposable?.dispose()
        canStepForwardDisposable = nil
        
        canStepForwardDisposable = currentItem.rx.canStepForward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveForwardButton.isEnabled = $0
            })
        
        
        // 뒤로 이동 가능 여부 확인
        canStepBackwardDisposable?.dispose()
        canStepBackwardDisposable = nil
        
        canStepBackwardDisposable = currentItem.rx.canStepBackward()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.moveBackwardButton.isEnabled = $0
            })
        
        
        // 뒤로 이동 가능 여부 확인
        canPlayFastReverseDisposable?.dispose()
        canPlayFastReverseDisposable = nil
        
        canPlayFastReverseDisposable = currentItem.rx.canPlayFastReverse()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.backwardButton.isEnabled = $0
                self.repeatButton.isEnabled = $0
            })
        
        
        // playerItem Status에 따라 버튼 UI 변경
        statusDisposable?.dispose()
        statusDisposable = nil
        
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
        
        
        // 현재 미디어 아이템의 남은시간 표시
        durationDisposable?.dispose()
        durationDisposable = nil
        
        durationDisposable = currentItem.rx.duration
            .map { [unowned self] in self.createTimeString(time: Float($0.seconds)) }
            .bind(to: durationLabel.rx.text)
        
        
        // 현재 아이템 재생 완료 시 다음 아이템 자동 재생
        didPlayToEndDisposable?.dispose()
        didPlayToEndDisposable = nil
        
        didPlayToEndDisposable = currentItem.rx.didPlayToEnd
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let currentItemIndex = self.currentItemIndex else { return }
                
                if currentItemIndex < self.currentItemsForPlayer.count {
                    self.playNextVideo(self.avPlayer)
                }
            })
    }
    
    
    // MARK: - Update UI based on Player Item Status
    
    /// playerItem이 fail인 경우 표시할 UI
    private func updateUIForPlayerItemFailedState() {
        playPauseButton.isEnabled = true
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackwardButton.isEnabled = false
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
        moveBackwardButton.isEnabled = true
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
        playPauseButton.isEnabled = true
        timeSlider.isEnabled = false
        startTimeLabel.isEnabled = false
        durationLabel.isEnabled = false
        moveBackwardButton.isEnabled = false
        moveForwardButton.isEnabled = false
        nextVideoButton.isEnabled = false
        previousVideoButton.isEnabled = false
        forwardButton.isEnabled = false
        backwardButton.isEnabled = false
    }
}


