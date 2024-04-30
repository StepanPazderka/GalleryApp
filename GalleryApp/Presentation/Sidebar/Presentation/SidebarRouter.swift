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
    var rightDetailNavigationController = UINavigationController()
    
    init(container: Container) {
        self.container = container
    }
    
    public func setup(splitViewController: UISplitViewController) {
        self.splitViewController = splitViewController

        let sidebarViewController = container.resolve(SidebarViewController.self)!
        
        splitViewController.viewControllers = [sidebarViewController, rightDetailNavigationController]

        splitViewController.setViewController(rightDetailNavigationController, for: .secondary)
        splitViewController.setViewController(sidebarViewController, for: .primary)
        splitViewController.preferredDisplayMode = .automatic
        splitViewController.presentsWithGesture = true
    }
    
    public func showAllPhotos() {
        let allPhotosVC = container.resolve(AlbumScreenViewController.self)!
        rightDetailNavigationController.setViewControllers([allPhotosVC], animated: false)
        splitViewController.showDetailViewController(rightDetailNavigationController, sender: nil)
    }
    
    public func show(album albumID: UUID) {
        let albumVC = container.resolve(AlbumScreenViewController.self, argument: albumID)!
        rightDetailNavigationController.setViewControllers([albumVC], animated: false)
        splitViewController.showDetailViewController(rightDetailNavigationController, sender: nil)
    }
    
    public func showLibrarySelectionScreen() {
        let librarySelectionScreen = container.resolve(SelectLibraryViewController.self)!
        splitViewController.present(UINavigationController(rootViewController: librarySelectionScreen), animated: true)
    }
}
