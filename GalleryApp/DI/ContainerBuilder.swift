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
        
        container = registerTransient()
        
        return container
    }
    
    static func registerTransient() -> Container {
        let transientContainer = Container(parent: container, defaultObjectScope: .transient)
        
        transientContainer.register(PhotoDetailViewModel.self) { (r, settings: PhotoDetailModel) in
            return PhotoDetailViewModel(galleryManager: r.resolve(GalleryManager.self)!, settings: settings, pathResolver: r.resolve(PathResolver.self)!)
        }
        
        transientContainer.register(PhotoDetailViewController.self) { (r, photoDetailSettings: PhotoDetailModel) in
            return PhotoDetailViewController(viewModel: r.resolve(PhotoDetailViewModel.self,
                                                                  argument: photoDetailSettings)!)
        }
        
        transientContainer.register(AlbumsListViewModel.self) { r in
            return AlbumsListViewModel(galleryManager: r.resolve(GalleryManager.self)!, pathResolver: r.resolve(PathResolver.self)!)
        }.inObjectScope(.transient)
        
        transientContainer.register(PhotoPropertiesViewModel.self) { (r, images: [GalleryImage]) in
            return PhotoPropertiesViewModel(images: images, galleryManager: r.resolve(GalleryManager.self)!, pathResolver: r.resolve(PathResolver.self)!)
        }
        
        transientContainer.register(PhotoPropertiesViewController.self) { (r, images: [GalleryImage]) in
            return PhotoPropertiesViewController(viewModel: transientContainer.resolve(PhotoPropertiesViewModel.self, argument: images)!)
        }
        
        container.register(SelectLibraryViewModel.self) { r in
			return SelectLibraryViewModel(settingsManager: r.resolve(SettingsManagerImpl.self)!, galleryManagery: r.resolve(GalleryManager.self)!)
        }
        
        self.container = transientContainer
        return transientContainer
    }
    
    static func registerDataLayer() {
        container.register(UnsecureStorage.self) { r in
            return UnsecureStorage()
        }
        
        container.register(SettingsManagerImpl.self) { r in
            return SettingsManagerImpl(unsecureStorage: r.resolve(UnsecureStorage.self)!)
        }
        
        container.register(PathResolver.self) { r in
			return PathResolver(settingsManager: r.resolve(SettingsManagerImpl.self)!)
        }
        
        container.register(GalleryManager.self) { r in
            return GalleryManagerImpl(settingsManager: r.resolve(SettingsManagerImpl.self)!,
                                       pathResolver: r.resolve(PathResolver.self)!)
        }
    }
    
    static func registerPresentationLayer() {
		container.register(SplitViewController.self) { r in
			return SplitViewController()
		}
		
        container.register(AlbumListRouter.self) { r in
            return AlbumListRouter()
        }
        
        container.register(SelectLibraryViewController.self) { r in
			return SelectLibraryViewController(viewModel: r.resolve(SelectLibraryViewModel.self)!, pathResolver: r.resolve(PathResolver.self)!)
        }
        
        container.register(MainRouter.self) { r in
            return MainRouter(container: container)
        }
        
        container.register(SidebarViewModel.self) { r in
            return SidebarViewModel(galleryInteractor: r.resolve(GalleryManager.self)!,
                                    settingsManager: r.resolve(SettingsManagerImpl.self)!,
                                    pathResolver: r.resolve(PathResolver.self)!)
        }
        
        container.register(SidebarViewController.self) { r in
            return SidebarViewController(router: r.resolve(MainRouter.self)!,
                                         container: container,
                                         viewModel: r.resolve(SidebarViewModel.self)!)
        }
        
        container.register(AlbumScreenRouter.self) { r in
            return AlbumScreenRouter(mainRouter: r.resolve(MainRouter.self)!,
                                     container: container)
        }
        
        container.register(AlbumScreenViewController.self) { r in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: r.resolve(AlbumScreenViewModel.self)!,
											 pathResolver: r.resolve(PathResolver.self)!)
        }.inObjectScope(.container)
        
        container.register(AlbumScreenViewModel.self) { r in
            return AlbumScreenViewModel(albumID: nil,
                                        galleryManager: r.resolve(GalleryManager.self)!,
                                        pathResolver: r.resolve(PathResolver.self)!)
        }.inObjectScope(.container)
        
        container.register(AlbumScreenViewModel.self) { (r, albumID: UUID) in
            return AlbumScreenViewModel(albumID: albumID,
                                        galleryManager: r.resolve(GalleryManager.self)!,
                                        pathResolver: r.resolve(PathResolver.self)!)
        }.inObjectScope(.transient)
        
        container.register(AlbumScreenViewController.self) { (r, albumID: UUID) in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!,
                                             viewModel: r.resolve(AlbumScreenViewModel.self,
                                                                  argument: albumID)!,
											 pathResolver: r.resolve(PathResolver.self)!)
        }.inObjectScope(.transient)
        
        container.register(AlbumsListViewController.self) { (r, selectedImages: [GalleryImage]) in
            return AlbumsListViewController(selectedImages: selectedImages, router: r.resolve(AlbumListRouter.self)!, viewModel: r.resolve(AlbumsListViewModel.self)!)
        }.inObjectScope(.transient)
    }
}
