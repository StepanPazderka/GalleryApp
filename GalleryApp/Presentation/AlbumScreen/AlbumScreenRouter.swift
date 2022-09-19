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
    let sidebarRouter: SidebarRouter
    var navigationController: UINavigationController?
    var isEditing = BehaviorRelay<Bool>.init(value: false)
    
    internal init(sidebarRouter: SidebarRouter) {
        self.sidebarRouter = sidebarRouter
    }
    
    func start(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func showDetails() {
//        sidebarRouter.showDetails()
        
    }
    
    func showPhotoDetail(images: [AlbumImage], index: Int) {
        let vc = ContainerBuilder.build().resolve(PhotoDetailViewController.self, argument: PhotoDetailViewControllerSettings(selectedImages: images, selectedIndex: index))!
        vc.modalPresentationStyle = .none
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showDocumentPicker() {
        
    }
    
    func showDetails(images: [UUID]) {
        let vc = ItemDetailViewController()
        sidebarRouter.splitViewController.present(vc, animated: true)
    }
}
