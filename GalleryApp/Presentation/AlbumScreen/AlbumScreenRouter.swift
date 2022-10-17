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
    let sidebarRouter: SidebarRouter
    var navigationController: UINavigationController?
    var isEditing = BehaviorRelay<Bool>.init(value: false)
    let container: Container
    
    // MARK: - Init
    internal init(sidebarRouter: SidebarRouter, container: Container) {
        self.sidebarRouter = sidebarRouter
        self.container = container
    }
    
    func start(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func showDetails() {
//        sidebarRouter.showDetails()
    }
    
    func showPhotoDetail(images: [AlbumImage], index: Int) {
        let vc = container.resolve(PhotoDetailViewController.self, argument: PhotoDetailViewControllerSettings(selectedImages: images, selectedIndex: index))!
//        self.navigationController?.pushViewController(vc, animated: true)
        let navigationController = UINavigationController(rootViewController: vc)
        
        navigationController.modalPresentationStyle = .fullScreen
        topMostController()?.present(navigationController, animated: true)
    }
    
    func showDocumentPicker() {
        
    }
    
    func showDetails(images: [AlbumImage]) {
        let vc = container.resolve(PhotoPropertiesViewController.self, argument: images)!
        sidebarRouter.splitViewController.present(vc, animated: true)
    }
}
