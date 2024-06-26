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
    private let mainRouter: MainRouter
    private var navigationController: UINavigationController?
    private let container: Container
    
    // MARK: - Init
    internal init(mainRouter: MainRouter, container: Container) {
        self.mainRouter = mainRouter
        self.container = container
    }
    
    func setup(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func showPhotoDetail(images: [GalleryImage], index: IndexPath) {
        let settings = PhotoDetailModel(selectedImages: images, selectedIndex: index)
        let PhotoDetailVC = container.resolve(PhotoDetailViewController.self, argument: settings)!
        let photoDetailNavigationViewController = UINavigationController(rootViewController: PhotoDetailVC)
        photoDetailNavigationViewController.modalPresentationStyle = .fullScreen
        topMostController()?.present(photoDetailNavigationViewController, animated: true)
    }
    
    func showMoveToAlbumScreen(with images: [GalleryImage]) {
        let AlbumListViewController = container.resolve(AlbumsListViewController.self, argument: images)!
        let albumsListNavigationViewController = UINavigationController(rootViewController: AlbumListViewController)
        AlbumListViewController.viewModel.delegate = navigationController?.children.first as? any AlbumListViewControllerDelegate
        albumsListNavigationViewController.view.backgroundColor = .systemBackground
        topMostController()?.present(albumsListNavigationViewController, animated: true, completion: nil)
    }
    
    func showDocumentPicker() {
        
    }
    
    func showPropertiesScreen(of images: [GalleryImage]) {
        let vc = container.resolve(PhotoPropertiesViewController.self, argument: images)!
        mainRouter.splitViewController.present(vc, animated: true)
    }
}
