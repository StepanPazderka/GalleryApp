//
//  MainRouter.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.01.2022.
//

import Foundation
import UIKit
import Swinject

class MainRouter {
    var splitViewController: UISplitViewController
    var container: Container
    
    init(splitViewController: UISplitViewController, container: Container) {
        self.splitViewController = splitViewController
        self.container = container
    }
    
    func start() {
        splitViewController.setViewController(SidebarViewController(galleryInteractor: container.resolve(GalleryManager.self)!, container: self.container), for: .primary)
        toggleSidebar()
    }
    
    func toggleSidebar() {
//        splitViewController.hide(.primary)
//        splitViewController.
    }
}
