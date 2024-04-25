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
		do {
			try self.galleryManager.move(images: images, toAlbum: album)
			self.shouldDismiss.accept(true)
			self.delegate?.didFinishMovingImages()
		} catch GalleryManagerError.imageAlreadyInAlbum {
			showErrorCantAddImageToAlbum.accept(true)
		} catch {
			shouldDismiss.accept(true)
		}
    }
    
    func fetchAlbums() -> Observable<[SidebarSectionModel]> {
        self.galleryManager.loadCurrentGalleryIndexAsObservable().map { index in
            return index.albums.compactMap { albumID in
                if let album = self.galleryManager.loadAlbumIndex(with: albumID) {
                    var thumbnailImage: UIImage?

                    if let FirstAlbumImage = album.images.first {
                        let path = self.pathResolver.resolveThumbPathFor(imageName: FirstAlbumImage.fileName)
                        
                        let thumbnailImageURL = self.pathResolver.selectedGalleryPath.appendingPathComponent(FirstAlbumImage.fileName)
                        thumbnailImage = UIImage(contentsOfFile: path)
                    }
                    
                    if let thumbnail = album.thumbnail {
                        if !thumbnail.isEmpty && !album.images.isEmpty {
                            let thumbnailImageURL = self.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnail)
                            thumbnailImage = UIImage(contentsOfFile: thumbnailImageURL.relativePath)
                        }
                    }
                    return SidebarItem(id: UUID(uuidString: albumID.uuidString), title: album.name, image: thumbnailImage ?? nil, buttonType: .album)
                } else {
                    return nil
                }
            }
        }.map { items in
			return [SidebarSectionModel(type: .albumButtons, name: "Albums", items: items)]
        }.asObservable()
    }
}
