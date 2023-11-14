//
//  AlbumListViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 12.10.2022.
//

import Foundation
import RxCocoa
import RxSwift

class AlbumsListViewModel {
    
    // MARK: - Properties
    let galleryManager: GalleryManager
    let pathResolver: PathResolver
    let showErrorCantAddImageToAlbum = BehaviorRelay(value: false)
    let shouldDismiss = BehaviorRelay(value: false)
    
    var delegate: AlbumListViewControllerDelegate?
    
    // MARK: - Init
    init(galleryManager: GalleryManager, pathResolver: PathResolver) {
        self.galleryManager = galleryManager
        self.pathResolver = pathResolver
    }

    func moveToAlbum(images: [GalleryImage], album: UUID) {
        for image in images {
            do {
                try self.galleryManager.move(Image: image, toAlbum: album)
                self.shouldDismiss.accept(true)
                self.delegate?.didFinishMovingImages()
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
                        let path = self.pathResolver.resolveThumbPathFor(imageName: FirstAlbumImage.fileName)
                        
                        let thumbnailImageURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(FirstAlbumImage.fileName)
                        thumbnailImage = UIImage(contentsOfFile: path)
                    }
                    
                    if let thumbnail = album.thumbnail {
                        if !thumbnail.isEmpty && !album.images.isEmpty {
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
