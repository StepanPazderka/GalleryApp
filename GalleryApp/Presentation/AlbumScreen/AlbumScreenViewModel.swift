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
    
    // MARK: -- Properties
    var isEditing = BehaviorSubject(value: false)
    var albumID: UUID?
    var albumIndex: AlbumIndex?
    let galleryManager: GalleryManager
    var shownImagesPaths = [AlbumImage]()
    let thumbnailSize: Float = 200
    
    let disposeBag = DisposeBag()
    
    internal init(albumID: UUID? = nil, galleryManager: GalleryManager) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        
        if let albumID = albumID {
            galleryManager.loadAlbumIndex(id: albumID).subscribe(onNext: { [weak self] albumIndex in
                self?.albumIndex = albumIndex
            }).disposed(by: disposeBag)
        } else {
            if let images = galleryManager.loadGalleryIndex()?.images {
                shownImagesPaths = images
            }
            galleryManager.selectedGalleryIndexRelay.subscribe(onNext: { galleryIndex in
                self.shownImagesPaths = galleryIndex.images
            }).disposed(by: disposeBag)
        }
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
        self.galleryManager.selectedGalleryIndexRelay
    }
    
    func galleryIndexRelay() -> PublishSubject<GalleryIndex> {
        self.galleryManager.selectedGalleryIndexRelay
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
    
    func addPhoto(image: AlbumImage, callback: (() -> Void)? = nil) {
        self.galleryManager.addImage(photoID: image.fileName, toAlbum: albumID ?? nil)
        self.shownImagesPaths = self.galleryManager.loadGalleryIndex()?.images ?? []
        if let callback = callback {
            callback()
        }
    }
}
