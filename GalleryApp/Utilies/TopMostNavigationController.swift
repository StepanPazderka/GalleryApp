//
//  TopMostNavigationController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 15.10.2022.
//

import Foundation
import UIKit

func topMostController() -> UIViewController? {
    guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
        return nil
    }

    var topController = rootViewController

    while let newTopController = topController.presentedViewController {
        topController = newTopController
    }

    return topController
}
