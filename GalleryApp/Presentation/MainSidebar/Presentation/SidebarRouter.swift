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
        return view
    }()
    var container: Container
    let galleryManager: GalleryManager
    var navVC = UINavigationController()
    
    init(container: Container, galleryManager: GalleryManager) {
        self.container = container
        self.galleryManager = galleryManager
    }
    
    public func start(splitViewController: UISplitViewController) {
        self.splitViewController = splitViewController

        let sidebarViewController = container.resolve(SidebarViewController.self)!
        
        splitViewController.viewControllers = [sidebarViewController, navVC]

        splitViewController.setViewController(navVC, for: .secondary)
        splitViewController.setViewController(sidebarViewController, for: .primary)
        splitViewController.preferredDisplayMode = .automatic
        splitViewController.presentsWithGesture = true
    }
    
    public func showAllPhotos() {
        let allPhotosVC = container.resolve(AlbumScreenViewController.self)!
        navVC.setViewControllers([allPhotosVC], animated: false)
        splitViewController.showDetailViewController(navVC, sender: nil)
    }
    
    public func show(album albumID: UUID) {
        let albumVC = container.resolve(AlbumScreenViewController.self, argument: albumID)!
        navVC.setViewControllers([albumVC], animated: false)
        splitViewController.showDetailViewController(navVC, sender: nil)
    }
    
    public func showLibrarySelectionScreen() {
        let librarySelectionScreen = container.resolve(SelectLibraryViewController.self)!
        splitViewController.present(UINavigationController(rootViewController: librarySelectionScreen), animated: true)
    }
}
