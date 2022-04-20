//
//  ContainerBuilder.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.12.2021.
//

import Foundation
import Swinject

class ContainerBuilder {
    static func build() -> Container {
        let container = Container(parent: nil, defaultObjectScope: .container)
        
        container.register(Config.self) { r in
            return Config()
        }
        
        container.register(GalleryManager.self) { r in
            return GalleryManager(config: r.resolve(Config.self)!)
        }
        
        container.register(AlbumScreenViewController.self) { (r, albumName: String) in
            return AlbumScreenViewController(galleryInteractor: r.resolve(GalleryManager.self)!, albumName: albumName)
        }
        
        container.register(AlbumScreenViewController.self) { r in
            return AlbumScreenViewController(galleryInteractor: r.resolve(GalleryManager.self)!)
        }
        
        container.register(PhotoDetailViewController.self) { r in
            return PhotoDetailViewController(nibName: "PhotoDetailViewController", bundle: nil, galleryInteractor: r.resolve(GalleryManager.self)!)
        }
        
        container.register(PhotoDetailViewControllerNew.self) { (r, photoDetailSettings: PhotoDetailViewControllerSettings) in
            return PhotoDetailViewControllerNew(galleryInteractor: r.resolve(GalleryManager.self)!, sidebar: r.resolve(SidebarViewController.self)!, settings: photoDetailSettings)
        }
        
        container.register(SidebarViewController.self) { r in
            return SidebarViewController(galleryInteractor: r.resolve(GalleryManager.self)!, container: container)
        }
        
        container.register(SidebarRouter.self) { r in
            return SidebarRouter()
        }
        
        container.register(AlbumsViewController.self) { r in
            return AlbumsViewController(galleryInteractor: r.resolve(GalleryManager.self)!,container: container)
        }
                
        return container
    }
}
