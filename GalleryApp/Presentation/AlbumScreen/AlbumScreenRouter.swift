//
//  AlbumScreenRouter.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 26.04.2022.
//

import Foundation
import UIKit
import Swinject
import RxCocoa

class AlbumScreenRouter {
    
    // MARK: - Properties
    private let sidebarRouter: SidebarRouter
    private var navigationController: UINavigationController?
    private let container: Container
    
    // MARK: - Init
    internal init(sidebarRouter: SidebarRouter, container: Container) {
        self.sidebarRouter = sidebarRouter
        self.container = container
    }
    
    func start(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func showPhotoDetail(images: [AlbumImage], index: IndexPath) {
        let settings = PhotoDetailModel(selectedImages: images, selectedIndex: index)
        let PhotoDetailVC = container.resolve(PhotoDetailViewController.self, argument: settings)!
        let navigationController = UINavigationController(rootViewController: PhotoDetailVC)
        navigationController.modalPresentationStyle = .fullScreen
        topMostController()?.present(navigationController, animated: true)
    }
    
    func showDocumentPicker() {
        
    }
    
    func showPropertiesScreen(of images: [AlbumImage]) {
        let vc = container.resolve(PhotoPropertiesViewController.self, argument: images)!
        sidebarRouter.splitViewController.present(vc, animated: true)
    }
}
