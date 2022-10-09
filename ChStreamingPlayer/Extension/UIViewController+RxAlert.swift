//
//  UIViewController+Alert.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/23/22.
//

import UIKit
import RxSwift


enum ActionType {
    case ok
    case cancel
}


extension UIViewController {
    
    func alertPressPlayButton(title: String, message: String? = nil) -> Observable<ActionType> {
        return Observable.create { [weak self] (observer) in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                observer.onNext(.ok)
                observer.onCompleted()
            }
            alert.addAction(okAction)
            
            self?.present(alert, animated: true, completion: nil)
            
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func alertToPlayer(title: String, message: String? = nil) -> Observable<ActionType> {
        return Observable.create { [weak self] (observer) in
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                observer.onNext(.ok)
                observer.onCompleted()
            }
            alert.addAction(okAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                observer.onNext(.cancel)
                observer.onCompleted()
            }
            alert.addAction(cancelAction)
            
            self?.present(alert, animated: true)
            
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
}
