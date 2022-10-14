//
//  ContainerBuilder.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.12.2021.
//

import Foundation
import Swinject
import UIKit

class ContainerBuilder {
    static let container = Container(parent: nil, defaultObjectScope: .container)
    static var linkTransientContainer: Container = Container()
    
    static func build() -> Container {

        registerDataLayer()
        registerPresentationLayer()

        container.register(AlbumsListViewController.self) { (r, selectedImages: [String]) in
            return AlbumsListViewController(galleryInteractor: r.resolve(GalleryManager.self)!, container: container, selectedImages: selectedImages)
        }

        let transientContainer = Container(parent: container, defaultObjectScope: .transient)

        transientContainer.register(PhotoDetailViewController.self) { (r, photoDetailSettings: PhotoDetailViewControllerSettings) in
            return PhotoDetailViewController(galleryInteractor: r.resolve(GalleryManager.self)!, sidebar: r.resolve(SidebarViewController.self)!, settings: photoDetailSettings)
        }

        transientContainer.register(AlbumScreenViewModel.self) { (r, albumID: UUID) in
            return AlbumScreenViewModel(albumID: albumID,
                                        galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        transientContainer.register(AlbumScreenViewController.self) { (r, albumID: UUID) in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: linkTransientContainer.resolve(AlbumScreenViewModel.self,
                                                                  argument: albumID)!)
        }

        linkTransientContainer = transientContainer
        return transientContainer
    }

    static func registerDataLayer() {
        container.register(UnsecureStorage.self) { r in
            return UnsecureStorage()
        }

        container.register(SettingsManager.self) { r in
            return SettingsManager(unsecureStorage: r.resolve(UnsecureStorage.self)!)
        }

        container.register(FileScannerManager.self) { r in
            return FileScannerManager(settings: r.resolve(SettingsManager.self)!)
        }

        container.register(GalleryManager.self) { r in
            return GalleryManager(settingsManager: r.resolve(SettingsManager.self)!,
                                  fileScannerManger: r.resolve(FileScannerManager.self)!)
        }
    }
    
    static func registerPresentationLayer() {
        container.register(SidebarRouter.self) { r in
            return SidebarRouter(container: container, transientContainer: linkTransientContainer, galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        container.register(SidebarViewModel.self) { r in
            return SidebarViewModel(galleryInteractor: r.resolve(GalleryManager.self)!)
        }
        
        container.register(SidebarViewController.self) { r in
            return SidebarViewController(router: r.resolve(SidebarRouter.self)!,
                                         container: container,
                                         viewModel: r.resolve(SidebarViewModel.self)!)
        }

        container.register(AlbumScreenRouter.self) { r in
            return AlbumScreenRouter(sidebarRouter: r.resolve(SidebarRouter.self)!,
                                     container: linkTransientContainer)
        }
        
        container.register(AlbumScreenViewModel.self) { r in
            return AlbumScreenViewModel(albumID: nil,
                                        galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        container.register(AlbumScreenViewModel.self) { (r, albumID: UUID) in
            return AlbumScreenViewModel(albumID: albumID,
                                        galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        container.register(AlbumScreenViewController.self) { (r, albumID: UUID) in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: r.resolve(AlbumScreenViewModel.self,
                                                                  argument: albumID)!)
        }
        
        container.register(AlbumScreenViewController.self) { r in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: r.resolve(AlbumScreenViewModel.self)!)
        }
    }
}
