//
//  MainRouter.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.01.2022.
//

import Foundation
import UIKit
import Swinject

class SidebarRouter {
    var splitViewController: UISplitViewController = {
        let view = UISplitViewController(style: .doubleColumn)
        view.preferredDisplayMode = .oneBesideSecondary
        view.presentsWithGesture = true
        view.preferredSplitBehavior = .tile
        return view
    }()
    var container: Container
    let galleryManager: GalleryManager
    var navVC = UINavigationController()
    
    init(container: Container, galleryManager: GalleryManager) {
        self.container = container
        self.galleryManager = galleryManager
    }
    
    func start(splitViewController: UISplitViewController) {
        self.splitViewController = splitViewController

        let masterVC = UINavigationController(rootViewController: container.resolve(SidebarViewController.self)!)
        
        splitViewController.viewControllers = [masterVC, navVC]

        splitViewController.setViewController(navVC, for: .secondary)
        splitViewController.setViewController(masterVC, for: .primary)
        splitViewController.preferredDisplayMode = .automatic
        splitViewController.presentsWithGesture = true
    }
    
    func showAllPhotos() {
        let allPhotosVC = container.resolve(AlbumScreenViewController.self)!
        navVC.setViewControllers([allPhotosVC], animated: false)
        splitViewController.showDetailViewController(navVC, sender: nil)
    }
    
    func show(album albumID: UUID) {
        let albumVC = container.resolve(AlbumScreenViewController.self, argument: albumID)!
        navVC.setViewControllers([albumVC], animated: false)
        splitViewController.showDetailViewController(navVC, sender: nil)
    }
    
    func showLibrarySelectionScreen() {
        let librarySelectionScreen = container.resolve(SelectLibraryViewController.self)!
        splitViewController.present(UINavigationController(rootViewController: librarySelectionScreen), animated: true)
    }
    
    func showDetails() {
//        splitViewController.preferredSupplementaryColumnWidth = CGFloat(250.0)
//        splitViewController.setViewController(UIViewController(), for: .supplementary)
    }
}
