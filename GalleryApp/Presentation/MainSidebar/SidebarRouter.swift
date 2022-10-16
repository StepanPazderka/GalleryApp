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
    var transientContainer: Container
    let galleryManager: GalleryManager
    
    init(container: Container, transientContainer: Container, galleryManager: GalleryManager) {
        self.container = container
        self.transientContainer = transientContainer
        self.galleryManager = galleryManager
    }
    
    func start(splitViewController: UISplitViewController) {
        self.splitViewController = splitViewController
        splitViewController.setViewController(container.resolve(SidebarViewController.self)!, for: .primary)
    }
    
    func showAllPhotos() {
        let allPhotosVC = container.resolve(AlbumScreenViewController.self)!
        splitViewController.setViewController(UINavigationController(rootViewController: allPhotosVC), for: .secondary)
    }
    
    func show(album albumID: UUID) {
        let albumVC = container.resolve(AlbumScreenViewController.self, argument: albumID)!
        splitViewController.setViewController(UINavigationController(rootViewController: albumVC), for: .secondary)
    }
    
    func showDetails() {
//        splitViewController.preferredSupplementaryColumnWidth = CGFloat(250.0)
//        splitViewController.setViewController(UIViewController(), for: .supplementary)
    }
}
