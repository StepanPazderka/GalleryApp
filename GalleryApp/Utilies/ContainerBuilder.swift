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
    static var container = Container(parent: nil, defaultObjectScope: .container)
    
    static func build() -> Container {
        
        registerDataLayer()
        registerPresentationLayer()
        
        container.register(AlbumsListViewController.self) { (r, selectedImages: [GalleryImage]) in
            return AlbumsListViewController(galleryInteractor: r.resolve(GalleryManager.self)!, container: container, selectedImages: selectedImages, router: r.resolve(AlbumListRouter.self)!)
        }
        
        container = registerTransient()
        
        return container
    }
    
    static func registerTransient() -> Container {
        let container = Container(parent: container, defaultObjectScope: .transient)
        
        container.register(PhotoDetailViewModel.self) { (r, settings: PhotoDetailModel) in
            return PhotoDetailViewModel(galleryManager: r.resolve(GalleryManager.self)!, settings: settings)
        }
        
        container.register(PhotoDetailViewController.self) { (r, photoDetailSettings: PhotoDetailModel) in
            return PhotoDetailViewController(viewModel: r.resolve(PhotoDetailViewModel.self,
                                                                  argument: photoDetailSettings)!)
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
        
        container.register(PhotoPropertiesViewModel.self) { (r, images: [GalleryImage]) in
            return PhotoPropertiesViewModel(images: images, galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        container.register(PhotoPropertiesViewController.self) { (r, images: [GalleryImage]) in
            return PhotoPropertiesViewController(viewModel: container.resolve(PhotoPropertiesViewModel.self, argument: images)!)
        }
        
        self.container = container
        return container
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
        container.register(AlbumListRouter.self) { r in
            return AlbumListRouter()
        }
        
        container.register(SelectLibraryViewModel.self) { r in
            return SelectLibraryViewModel(settingsManager: r.resolve(SettingsManager.self)!)
        }
        
        container.register(SelectLibraryViewController.self) { r in
            return SelectLibraryViewController(viewModel: r.resolve(SelectLibraryViewModel.self)!)
        }
        
        container.register(SidebarRouter.self) { r in
            return SidebarRouter(container: container, galleryManager: r.resolve(GalleryManager.self)!)
        }
        
        container.register(SidebarViewModel.self) { r in
            return SidebarViewModel(galleryInteractor: r.resolve(GalleryManager.self)!,
                                    settingsManager: r.resolve(SettingsManager.self)!)
        }
        
        container.register(SidebarViewController.self) { r in
            return SidebarViewController(router: r.resolve(SidebarRouter.self)!,
                                         container: container,
                                         viewModel: r.resolve(SidebarViewModel.self)!)
        }
        
        container.register(AlbumScreenRouter.self) { r in
            return AlbumScreenRouter(sidebarRouter: r.resolve(SidebarRouter.self)!,
                                     container: container)
        }
        
        container.register(AlbumScreenViewController.self) { r in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: r.resolve(AlbumScreenViewModel.self)!)
        }
        
        container.register(AlbumScreenViewModel.self) { r in
            return AlbumScreenViewModel(albumID: nil,
                                        galleryManager: r.resolve(GalleryManager.self)!)
        }
    }
}
