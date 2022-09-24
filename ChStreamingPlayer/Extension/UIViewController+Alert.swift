//
//  UIViewController+Alert.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 9/23/22.
//

import UIKit


extension UIViewController {
    
    func alertPressPlayButton(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
}
