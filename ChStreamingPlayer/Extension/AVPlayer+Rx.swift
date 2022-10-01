//
//  AVPlayer+Rx.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/27/22.
//
//  Copyright since 2015 Showmax s.r.o.

import Foundation
import AVFoundation
import RxSwift
import RxCocoa


extension Reactive where Base: AVPlayer
{
    /// Create observable which will emitt `AVPlayerStatus` every time player's status change. Only distinct values will be emitted.
    ///
    /// - Parameter options: Observing options which determine the values that are returned. These options are passed to KVO method.
    /// - Returns: Observable which emitt player's status every time it change.
    public func status(options: KeyValueObservingOptions) -> Observable<AVPlayer.Status>
    {
        return base.rx.observe(AVPlayer.Status.self, "status", options: options, retainSelf: false)
            .ignoreNil()
            .distinctUntilChanged()
    }
    
    
    /// Create observable which will emitt `Float` every time player's rate change. Only distinct values will be emitted.
    ///
    /// - Parameter options: Observing options which determine the values that are returned. These options are passed to KVO method.
    /// - Returns: Observable which emitt player's rate every time it change.
    public func rate(options: KeyValueObservingOptions) -> Observable<Float>
    {
        return base.rx.observe(Float.self, "rate", options: options, retainSelf: false)
            .ignoreNil()
            .distinctUntilChanged()
    }
    
    
    /// Create observable which will emitt `Bool` every time player's rate change. Only distinct values will be emitted.
    /// If rate is <= 0.0 then this will emitt `true`.
    ///
    /// - Parameter options: Observing options which determine the values that are returned. These options are passed to KVO method.
    /// - Returns: Observable which emitt paused state every time player's rate change.
    public func paused(options: KeyValueObservingOptions) -> Observable<Bool>
    {
        return base.rx.rate(options: options)
            .map({ $0 <= 0.0 })
            .distinctUntilChanged()
    }
    
    
    /// Create observable which will emitt `AVPlayerItem Array` every time player's rate change. Only distinct values will be emitted.
    ///
    /// - Parameter options: Observing options which determine the values that are returned. These options are passed to KVO method.
    /// - Returns: Observable which emitt AVPlayerItem Array every time player's items change.
    /// - Author: 김정민(kimjm010@icloud.com)
    public func items(options: KeyValueObservingOptions = [.initial, .new]) -> Observable<[AVPlayerItem]> {
        return base.rx.observe([AVPlayerItem].self, "items", options: options, retainSelf: false)
            .ignoreNil()
            .distinctUntilChanged()
    }
    
    
    /// Create observable which will emitt playback position.
    ///
    /// - Parameters:
    ///   - updateInterval: Interval in which is position updated.
    ///   - updateQueue: Queue which is used to update position. If this is set to `nil` then updates are done on main queue.
    /// - Returns: Observable which will emitt playback position time.
    /// - Author: 김정민(kimjm010@icloud.com)
    public func playbackPosition(updateInterval: TimeInterval = 1, updateQueue: DispatchQueue?) -> Observable<Float> {
        return Observable.create({[weak base] observer in
            
            guard let player = base else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let intervalTime = CMTime(seconds: updateInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let obj = player.addPeriodicTimeObserver(
                forInterval: intervalTime,
                queue: updateQueue,
                using: { positionTime in
                    
                    observer.onNext(Float(positionTime.seconds))
            })
            
            return Disposables.create {
                player.removeTimeObserver(obj)
            }
        })
    }
}

