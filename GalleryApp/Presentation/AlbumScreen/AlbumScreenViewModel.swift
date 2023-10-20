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
    var showImportError = BehaviorRelay(value: [String]())
    
    var albumID: UUID?
    let galleryManager: GalleryManager
    var images = [GalleryImage]()
    
    var importProgress = MutableProgress()
    var filesSelectedInEditMode = [GalleryImage]()
    let disposeBag = DisposeBag()
    
    internal init(albumID: UUID? = nil, galleryManager: GalleryManager) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        
        
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
                self.images = [GalleryImage]()
            }
            
            galleryManager.loadAlbumIndexAsObservable(id: albumID).subscribe(onNext: { [weak self] albumIndex in
                self?.images = albumIndex.images
            }).disposed(by: disposeBag)
        } else {
            if let newImages = galleryManager.loadGalleryIndex()?.images {
                self.images = newImages
            }
            galleryManager.selectedGalleryIndexRelay.subscribe(onNext: { [weak self] galleryIndex in
                self?.images = galleryIndex.images
                self?.showingTitles.accept(galleryIndex.showingAnnotations ?? false)
            }).disposed(by: disposeBag)
        }
        
        self.showingTitles.distinctUntilChanged().subscribe(onNext: { isShowingTitles in
            self.switchTitles(value: isShowingTitles)
        }).disposed(by: disposeBag)
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
        self.galleryManager.selectedGalleryIndexRelay.asObservable()
    }
    
    func loadAlbumImagesObservable() -> Observable<[GalleryImage]> {
        if let albumID {
            return galleryManager.loadAlbumIndexAsObservable(id: albumID).flatMap {
                Observable.just($0.images)
            }
        } else {
            return galleryManager.selectedGalleryIndexRelay.flatMap {
                Observable.just($0.images)
            }
        }
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
    
    func loadAlbumIndexAsObservable() -> Observable<AlbumIndex> {
        galleryManager.loadAlbumIndexAsObservable(id: albumID!)
    }
    
    func delete(_ images: [String]) {
        self.galleryManager.delete(images: images)
    }
    
    func removeFromAlbum(images: [GalleryImage]) {
        guard let albumID else { return }
        if var albumIndex: AlbumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
            for image in images {
                albumIndex.images.removeAll { $0.fileName == image.fileName}
            }
            
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func addPhotos(images: [GalleryImage]) {
        self.galleryManager.addImages(photos: images.map { $0.fileName }, toAlbum: albumID)
        if albumID != nil {
            self.images.append(contentsOf: images)
        } else {
            self.images = self.galleryManager.loadGalleryIndex()?.images ?? []
        }
    }
    
    func newThumbnailSize(size: Float) {
        if let albumID = albumID, var newIndex = loadAlbum(by: albumID) {
            newIndex.thumbnailsSize = size
            self.galleryManager.updateAlbumIndex(index: newIndex)
            print("Album Index thumb updated with size \(size)")
        }
        
        if var galleryIndex = self.galleryManager.loadGalleryIndex() {
            galleryIndex.thumbnailSize = size
            self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
            print("Gallery Manager thumb updated with size \(size)")
        }
    }
    
    func setAlbumThumbnailImage(image: GalleryImage) {
        if let albumID, var albumIndex = galleryManager.loadAlbumIndex(id: albumID) {
            albumIndex.thumbnail = image.fileName
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func duplicateItem(image: GalleryImage) {
        
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
    
    func resolveThumbPathFor(image: String) -> String {
        self.galleryManager.resolveThumbPathFor(imageName: image)
    }
    
    func handleFilesImport(urls: [URL]) {
        for url in urls {
            do {
                let filenameExtension = url.pathExtension.lowercased()
                let targetPath = self.galleryManager.selectedGalleryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(filenameExtension)
                
                try FileManager.default.moveItem(at: url, to: targetPath)
                let newImage = GalleryImage(fileName: targetPath.lastPathComponent, date: Date(), title: nil)
                self.galleryManager.buildThumbnail(forImage: newImage)
                self.addPhotos(images: [newImage])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func importPhotos(results: [PHPickerResult]) {
        guard !results.isEmpty else { return }
        
        var filesSelectedForImport = [GalleryImage]()
        var filenamesThatCouldntBeImported = [String]()
        
        for itemProvider in results.map(\.itemProvider) {
            
            let newTaskProgress = Progress(totalUnitCount: 1000)
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { filePath, error in
                guard let filePath else {
                    guard let suggestedName = itemProvider.suggestedName else { return }
                    filenamesThatCouldntBeImported.append(suggestedName)
                    newTaskProgress.completedUnitCount = newTaskProgress.totalUnitCount / 2
                    return
                }
                
                let filenameExtension = filePath.pathExtension.lowercased()
                
                if (error != nil) {
                    print("Error while copying files \(String(describing: error))")
                }
                
                let targetPath = self.galleryManager.selectedGalleryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(filenameExtension)
                do {
                    try FileManager.default.moveItem(at: filePath, to: targetPath)
                    newTaskProgress.completedUnitCount = newTaskProgress.totalUnitCount
                    self.galleryManager.buildThumbnail(forImage: GalleryImage(fileName: targetPath.lastPathComponent, date: Date()))
                    filesSelectedForImport.append(GalleryImage(fileName: targetPath.lastPathComponent, date: Date()))
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
                self.showImportError.accept(filenamesThatCouldntBeImported)
                stopTimer()
            }
        }
    }
}

extension AlbumScreenViewModel: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let photos = results
        self.importPhotos(results: photos)
    }
}
