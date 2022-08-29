//
//  AlbumScreenViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.12.2021.
//

import Foundation
import RxSwift
import RxCocoa

class AlbumScreenViewModel {
    
    var isEditing = BehaviorSubject(value: false)
    var albumID: UUID?
    var albumIndex: AlbumIndex?
    let galleryManager: GalleryManager
    var listedImages = [AlbumImage]()
    let disposeBag = DisposeBag()
    let thumbnailSize: Float = 200
    
    internal init(albumID: UUID? = nil, galleryManager: GalleryManager) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        
        if let albumID = albumID {
            galleryManager.loadAlbumIndex(id: albumID).subscribe(onNext: { [weak self] albumIndex in
                self?.albumIndex = albumIndex
            }).disposed(by: disposeBag)
        } else {
            galleryManager.loadGalleryIndex().subscribe(onNext: { galleryIndex in
                self.listedImages.append(contentsOf: galleryIndex.images)
            }).disposed(by: disposeBag)
        }
    }
    
    func importPhoto() {
        if let albumID = albumID {
            guard let albumName = loadAlbum(by: albumID)?.name else { return }
            galleryManager.rebuildAlbumIndex(folder: galleryManager.selectedGalleryPath.appendingPathComponent(albumName))
        }
    }
    
    func loadAlbumImages() -> Observable<AlbumImage> {
        return galleryManager.loadAlbumIndex(id: albumID!).flatMap { Observable.from($0.images) }
    }
    
    func loadAlbum(by: UUID) -> AlbumIndex? {
        return self.galleryManager.loadAlbumIndex(id: by)
    }
    
    func loadAlbumIndex() -> AlbumIndex {
        if let albumID = albumID, let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
            return albumIndex
        } else {
            return AlbumIndex.empty
        }
    }
    
    func deleteImage(imageName: String) {
        self.galleryManager.deleteImage(imageName: imageName)
    }
    
    func addPhoto(image: AlbumImage) {
        self.galleryManager.addImage(photoID: image.fileName, toAlbum: albumID ?? nil)
    }
}
