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
                if let album = self.galleryManager.loadAlbumIndex(id: albumID) {
                    var thumbnailImage: UIImage?

                    if let FirstAlbumImage = album.images.first {
                        let path = self.galleryManager.resolveThumbPathFor(imageName: FirstAlbumImage.fileName)
                        
                        let thumbnailImageURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(FirstAlbumImage.fileName)
                        thumbnailImage = UIImage(contentsOfFile: path)
                    }
                    
                    if let thumbnail = album.thumbnail {
                        if !thumbnail.isEmpty {
                            let thumbnailImageURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(thumbnail)
                            thumbnailImage = UIImage(contentsOfFile: thumbnailImageURL.relativePath)
                        }
                    }
                    return SidebarItem(id: UUID(uuidString: albumID.uuidString), title: album.name, image: thumbnailImage ?? nil, buttonType: .album)
                } else {
                    return nil
                }
            }
        }.map { items in
            return [SidebarSection(category: "Albums", items: items)]
        }.asObservable()
    }
}
