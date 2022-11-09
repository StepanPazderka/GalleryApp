//
//  AlbumScreenViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.12.2021.
//

import Foundation
import RxSwift
import RxCocoa
import FolderMonitorKit

class AlbumScreenViewModel {
    
    // MARK: -- Properties
    var isEditing = PublishRelay<Bool>()
    var showingTitles = BehaviorSubject(value: false)
    
    var albumID: UUID?
    var albumIndex: AlbumIndex?
    let galleryManager: GalleryManager
    var images = [AlbumImage]()
    let disposeBag = DisposeBag()
    
    internal init(albumID: UUID? = nil, galleryManager: GalleryManager) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        
        if let albumID {
            self.albumIndex = loadAlbum(by: albumID)
        }

        if let albumID {
            if var albumIndex: AlbumIndex = galleryManager.loadAlbumIndex(id: albumID) {
                let filteredImages = albumIndex.images.compactMap { albumImage in
                    if FileManager.default.fileExists(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(albumImage.fileName).relativePath) {
                        return albumImage
                    } else {
                        return nil
                    }
                }
                self.images = filteredImages
                albumIndex.images = filteredImages
                self.galleryManager.updateAlbumIndex(index: albumIndex)
            } else {
                self.images = [AlbumImage]()
            }
            
            galleryManager.loadAlbumIndex(id: albumID).subscribe(onNext: { [weak self] albumIndex in
                self?.albumIndex = albumIndex
                self?.images = albumIndex.images
            }).disposed(by: disposeBag)
        } else {
            if let newImages = galleryManager.loadGalleryIndex()?.images {
                self.images = newImages
            }
            galleryManager.selectedGalleryIndexRelay.subscribe(onNext: { galleryIndex in
                self.images = galleryIndex.images
            }).disposed(by: disposeBag)
        }
        
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
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
    
    func addPhoto(image: AlbumImage) {
        self.galleryManager.addImage(photoID: image.fileName, toAlbum: albumID ?? nil)
        if albumID != nil {
            self.images.append(image)
        } else {
            self.images = self.galleryManager.loadGalleryIndex()?.images ?? []
        }
    }
    
    func newThumbnailSize(size: Float) {
        
        
        if let albumID = albumID, var newIndex = loadAlbum(by: albumID) {
            let seconds = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                newIndex.thumbnailsSize = size
                self.galleryManager.updateAlbumIndex(index: newIndex)
            }
        }
        
        if albumIndex == nil, var galleryIndex = self.galleryManager.loadGalleryIndex() {
            let seconds = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                galleryIndex.thumbnailSize = size
                self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
            }
        }
    }
    
    func setAlbumThumbnail(imageName: String) {
        if var updatedAlbum = self.albumIndex {
            updatedAlbum.thumbnail = imageName
            self.galleryManager.updateAlbumIndex(index: updatedAlbum)
        }
    }
    
    func switchTitles() {
        
    }
}
