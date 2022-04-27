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
    var splitViewController: UISplitViewController = { let view = UISplitViewController(style: .doubleColumn)
        view.preferredDisplayMode = .oneBesideSecondary
        view.presentsWithGesture = true
        view.preferredSplitBehavior = .tile
        return view
    }()
    var container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    func start(splitViewController: UISplitViewController) {
        self.splitViewController = splitViewController
        splitViewController.setViewController(SidebarViewController(router: self, galleryInteractor: container.resolve(GalleryManager.self)!, container: self.container), for: .primary)
    }
    
    func showAllPhotos() {
        let allPhotosVC = container.resolve(AlbumScreenViewController.self)!
        splitViewController.setViewController(UINavigationController(rootViewController: allPhotosVC), for: .secondary)

    }
    
    func show(album: String) {
        let albumVC = container.resolve(AlbumScreenViewController.self, argument: album)!
//        splitViewController.setViewController(albumVC, for: .secondary)
        splitViewController.setViewController(UINavigationController(rootViewController: albumVC), for: .secondary)
    }
    
    func showDetails() {
//        splitViewController.preferredSupplementaryColumnWidth = CGFloat(250.0)
//        splitViewController.setViewController(UIViewController(), for: .supplementary)
    }
}
