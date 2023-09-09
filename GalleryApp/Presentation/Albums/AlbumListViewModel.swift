//
//  AlbumListViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 12.10.2022.
//

import Foundation
import RxCocoa
import RxSwift

class AlbumListViewModel {
    
    let galleryManager: GalleryManager
    let showErrorCantAddImageToAlbum = BehaviorRelay(value: false)
    let shouldDismiss = BehaviorRelay(value: false)
    
    init(galleryManager: GalleryManager) {
        self.galleryManager = galleryManager
    }

    func moveToAlbum(images: [String], album: UUID) {
        for image in images {
            do {
                try self.galleryManager.move(Image: AlbumImage(fileName: image, date: Date()), toAlbum: album)
                self.shouldDismiss.accept(true)
            } catch MoveImageError.imageAlreadyInAlbum {
                showErrorCantAddImageToAlbum.accept(true)
            } catch {
                shouldDismiss.accept(true)
            }
        }
    }
    
    func fetchAlbums() -> Observable<[SidebarSection]> {
        self.galleryManager.selectedGalleryIndexRelay.map { index in
            return index.albums.compactMap { albumID in
                if let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
                    var thumbnailImage: UIImage?
                    if let firstImage = albumIndex.images.first {
                        thumbnailImage = UIImage(contentsOfFile: self.galleryManager.resolveThumbPathFor(imageName: firstImage.fileName))
                    }
                    
                    if let setThumbnail = albumIndex.thumbnail {
                        thumbnailImage = UIImage(contentsOfFile: self.galleryManager.resolveThumbPathFor(imageName: setThumbnail))
                    }
                    
                    return SidebarItem(title: albumIndex.name, image: thumbnailImage ?? nil, buttonType: .album)
                }
                return nil
            }
        }.map { items in
            return [SidebarSection(category: "Albums", items: items)]
        }.asObservable()
    }
}
