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
    
    static func build() -> Container {
        container.register(Config.self) { r in
            return Config()
        }
        
        container.register(GalleryManager.self) { r in
            return GalleryManager(config: r.resolve(Config.self)!)
        }
        
        container.register(AlbumScreenViewController.self) { (r, albumName: String) in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!, galleryInteractor: r.resolve(GalleryManager.self)!, albumName: albumName)
        }
        
        container.register(AlbumScreenViewController.self) { r in
            return AlbumScreenViewController(router: r.resolve(AlbumScreenRouter.self)!, galleryInteractor: r.resolve(GalleryManager.self)!)
        }
        
        container.register(PhotoDetailViewController.self) { r in
            return PhotoDetailViewController(nibName: "PhotoDetailViewController", bundle: nil, galleryInteractor: r.resolve(GalleryManager.self)!)
        }
        
        container.register(SidebarRouter.self) { r in
            return SidebarRouter(container: container)
        }
        
        container.register(AlbumScreenRouter.self) { r in
            return AlbumScreenRouter(sidebarRouter: r.resolve(SidebarRouter.self)!)
        }
        
        container.register(SidebarViewController.self) { r in
            return SidebarViewController(router: r.resolve(SidebarRouter.self)!, galleryInteractor: r.resolve(GalleryManager.self)!, container: container)
        }
        
        container.register(AlbumsListViewController.self) { (r, selectedImages: [String]) in
            return AlbumsListViewController(galleryInteractor: r.resolve(GalleryManager.self)!,container: container, selectedImages: selectedImages)
        }
        
        let transientContainer = Container(parent: container, defaultObjectScope: .transient)
        transientContainer.register(PhotoDetailViewControllerNew.self) { (r, photoDetailSettings: PhotoDetailViewControllerSettings) in
            return PhotoDetailViewControllerNew(galleryInteractor: r.resolve(GalleryManager.self)!, sidebar: r.resolve(SidebarViewController.self)!, settings: photoDetailSettings)
        }

        return transientContainer
    }
}
