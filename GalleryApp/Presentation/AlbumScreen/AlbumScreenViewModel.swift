//
//  AlbumScreenViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.12.2021.
//

import Foundation
import RxSwift
import RxCocoa
import PhotosUI

class AlbumScreenViewModel {
    // MARK: -- Properties
    var isEditing = BehaviorRelay(value: false)
    var showingTitles = BehaviorRelay(value: false)
    var showingLoading = BehaviorRelay(value: false)
    
    var lastRecordedSliderValue: Float
    
    var albumID: UUID?
    var albumIndex: AlbumIndex?
    let galleryManager: GalleryManager
    var images = [AlbumImage]()
    
    var importProgress = MutableProgress()
    var showImportError = BehaviorRelay(value: [String]())
    var filesSelectedInEditMode = Array<String>()
    let disposeBag = DisposeBag()
    
    internal init(albumID: UUID? = nil, galleryManager: GalleryManager) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        
        let galleryIndex: GalleryIndex = self.galleryManager.loadGalleryIndex()!
        self.lastRecordedSliderValue = galleryIndex.thumbnailSize!
        
        if let albumID {
            self.albumIndex = loadAlbum(by: albumID)
            self.lastRecordedSliderValue = loadAlbum(by: albumID)?.thumbnailsSize ?? 0.0
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
                self.showingTitles.accept(albumIndex.showingAnnotations ?? false)
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
                self.showingTitles.accept(galleryIndex.showingAnnotations ?? false)
            }).disposed(by: disposeBag)
        }
        
        self.showingTitles.distinctUntilChanged().subscribe(onNext: { isShowingTitles in
            self.switchTitles(value: isShowingTitles)
        }).disposed(by: disposeBag)
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
        self.galleryManager.selectedGalleryIndexRelay.asObservable()
    }
    
    /**
     Loads images from Album as Observable
     */
    func loadAlbumImagesObservable() -> Observable<[AlbumImage]> {
        if let albumID {
            return galleryManager.loadAlbumIndex(id: albumID).flatMap {
                Observable.just($0.images.map { albumImage in
                    var newAlbumImage = albumImage
                    newAlbumImage.fileName = self.galleryManager.resolveThumbPathFor(imageName: albumImage.fileName)
                    return newAlbumImage
                })
            }
        } else {
            return galleryManager.selectedGalleryIndexRelay.flatMap {
                Observable.just($0.images.map { albumImage in
                    var newAlbumImage = albumImage
                    newAlbumImage.fileName = self.galleryManager.resolveThumbPathFor(imageName: albumImage.fileName)
                    return newAlbumImage
                })
            }
        }
    }
    
    /**
     Loads album Index by its unique UUID
     */
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
    
    func delete(_ images: [String]) {
        self.galleryManager.delete(images: images)
    }
    
    func removeFromAlbum(imageName: String) {
        guard let albumID else { return }
        
        if var albumIndex: AlbumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
            albumIndex.images.removeAll(where: { image in
                image.fileName == imageName
            })
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func addPhoto(image: AlbumImage) {
        self.galleryManager.addImage(photoID: image.fileName, toAlbum: albumID ?? nil)
        if albumID != nil {
            self.images.append(image)
        } else {
            self.images = self.galleryManager.loadGalleryIndex()?.images ?? []
        }
    }
    
    func addPhotos(images: [AlbumImage]) {
        self.galleryManager.addImages(photos: images.map { $0.fileName }, toAlbum: albumID)
        if albumID != nil {
            self.images.append(contentsOf: images)
        } else {
            self.images = self.galleryManager.loadGalleryIndex()?.images ?? []
        }
    }
    
    func newThumbnailSize(size: Float) {
        if let albumID = albumID, var newIndex = loadAlbum(by: albumID) {
            let seconds = 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                if size != self.lastRecordedSliderValue {
                    self.lastRecordedSliderValue = size
                } else {
                    newIndex.thumbnailsSize = size
                    self.galleryManager.updateAlbumIndex(index: newIndex)
                    print("Album Index thumb updated with size \(size)")
                }
            }
        }
        
        if albumIndex == nil, var galleryIndex = self.galleryManager.loadGalleryIndex() {
            let seconds = 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                if size != self.lastRecordedSliderValue {
                    self.lastRecordedSliderValue = size
                } else {
                    galleryIndex.thumbnailSize = size
                    self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
                    print("Gallery Manager thumb updated with size \(size)")
                }
            }
        }
    }
    
    func setAlbumThumbnailImage(imageName: String) {
        if var updatedAlbum = self.albumIndex {
            updatedAlbum.thumbnail = imageName
            self.galleryManager.updateAlbumIndex(index: updatedAlbum)
        }
    }
    
    func switchTitles(value: Bool) {
        if let albumID = albumID, var newIndex = loadAlbum(by: albumID) {
            newIndex.showingAnnotations = value
            self.galleryManager.updateAlbumIndex(index: newIndex)
        } else if var galleryIndex = self.galleryManager.loadGalleryIndex() {
            galleryIndex.showingAnnotations = value
            self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
        }
    }
    
    func importPhotos(results: [PHPickerResult]) {
        guard !results.isEmpty else { return }
        
        var filesSelectedForImport = [AlbumImage]()
        var filesThatCouldntBeImported = [String]()
        
        for itemProvider in results.map({ $0.itemProvider }) {
            
            let newTaskProgress = Progress(totalUnitCount: 1000)
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { filePath, error in
                guard let filePath else {
                    guard let suggestedName = itemProvider.suggestedName else { return }
                    filesThatCouldntBeImported.append(suggestedName)
                    newTaskProgress.completedUnitCount = newTaskProgress.totalUnitCount
                    return
                }
                
                let filenameExtension = filePath.pathExtension
                
                newTaskProgress.completedUnitCount = 0
                if (error != nil) {
                    print("Error while copying files \(String(describing: error))")
                }
                
                let targetPath = self.galleryManager.selectedGalleryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(filenameExtension)
                do {
                    try FileManager.default.moveItem(at: filePath, to: targetPath)
                    newTaskProgress.completedUnitCount = newTaskProgress.totalUnitCount
                    self.galleryManager.buildThumb(forImage: AlbumImage(fileName: targetPath.lastPathComponent, date: Date()))
                    filesSelectedForImport.append(AlbumImage(fileName: targetPath.lastPathComponent, date: Date()))
                    
                } catch {
                    print(error)
                }
            }
            self.importProgress.addChild(newTaskProgress)
        }
        
        
        self.showingLoading.accept(true)
        var timer: Timer?
        func stopTimer() {
            timer?.invalidate()
        }
        
        sleep(1)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            
            if self.importProgress.fractionCompleted == 1.0 {
                self.addPhotos(images: filesSelectedForImport)
                usleep(UInt32(0.25))
                self.showingLoading.accept(false)
                filesSelectedForImport.removeAll()
                self.showImportError.accept(filesThatCouldntBeImported)
                stopTimer()
            }
        }
    }
}
