//
//  UIViewController+Ex.swift
//  ChStreamingPlayer
//
//  Created by Chris Kim on 10/12/22.
//

import Foundation
import UIKit


extension UIViewController {
    
    func setTapBarAppearanceAsDefault() {
        if #available(iOS 15.0, *) {
            guard let tabBarController = self.tabBarController else { return }
            
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = tabBarController.tabBar.standardAppearance
        }
    }
}
