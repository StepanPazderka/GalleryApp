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
import Algorithms

class AlbumScreenViewModel {
    
    // MARK: -- Properties
    var isEditing = BehaviorRelay(value: false)
    var showingTitles = BehaviorRelay(value: false)
    var showingLoading = BehaviorRelay(value: false)
    var showImportError = BehaviorRelay(value: [String]())
    
    var albumID: UUID?
    let galleryManager: GalleryManager
    let pathResolver: PathResolver
    
    var importProgress = MutableProgress()
    var filesSelectedInEditMode = [GalleryImage]()
    
    var modelRelay = BehaviorSubject(value: AlbumScreenModel.empty)
    var model: AlbumScreenModel {
        didSet {
            updateModel(model: model)
            modelRelay.onNext(model)
        }
    }
    
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(albumID: UUID? = nil, galleryManager: GalleryManager, pathResolver: PathResolver) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        self.pathResolver = pathResolver
        
        if let albumID, let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
            self.model = AlbumScreenModel(from: albumIndex)
        } else if let galleryIndex = self.galleryManager.loadGalleryIndex()  {
            self.model = AlbumScreenModel(from: galleryIndex)
        } else {
            self.model = .empty
        }
        
        loadModel()
        
        self.modelRelay.distinctUntilChanged().subscribe(onNext: { [weak self] changedAlbumScreenModel in
            self?.updateModel(model: changedAlbumScreenModel)
        }).disposed(by: disposeBag)
    }
    
    func updateModel(model: AlbumScreenModel) {
        if albumID != nil, var galleryIndex = self.galleryManager.loadGalleryIndex() {
            let newAlbumIndex = AlbumIndex(from: model)
            self.galleryManager.updateAlbumIndex(index: newAlbumIndex)
            galleryIndex.images.append(contentsOf: model.images)
            let newGalleryImages = galleryIndex.images.uniqued(on: { GalleryImage in
                GalleryImage.fileName
            }).compactMap { $0 }
            galleryIndex.images = newGalleryImages
            self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
        } else if var galleryIndex = self.galleryManager.loadGalleryIndex() {
            galleryIndex.images = model.images.uniqued(on: { GalleryImage in
                GalleryImage.fileName
            }).compactMap { $0 }
            galleryIndex.thumbnailSize = model.thumbnailsSize
            galleryIndex.showingAnnotations = model.showingAnnotations
            galleryIndex.id = model.id
            self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
        }
    }
    
    func loadModel() {
        if let albumID, let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
            var thisScreenModel = AlbumScreenModel(from: albumIndex)
            let galleryIndex = self.galleryManager.loadGalleryIndex()
            thisScreenModel.images = thisScreenModel.images.map { albumImage in
                if let imageFromGalleryIndex = galleryIndex?.images.first(where: { galleryImage in
                    galleryImage.fileName == albumImage.fileName
                }) { return imageFromGalleryIndex } else { return albumImage }
            }
            self.modelRelay.onNext(thisScreenModel)
        } else if self.galleryManager.loadGalleryIndex() != nil  {
            self.galleryManager.selectedGalleryIndexRelay.distinctUntilChanged().subscribe(onNext: { galleryIndex in
                self.modelRelay.onNext(AlbumScreenModel(from: galleryIndex))
            }).disposed(by: disposeBag)
        }
    }
    
    func loadAlbum(by: UUID) -> AlbumIndex? {
        return self.galleryManager.loadAlbumIndex(id: by)
    }
    
    func loadAlbumIndexAsObservable() -> Observable<AlbumIndex> {
        galleryManager.loadAlbumIndexAsObservable(id: albumID!)
    }
    
    func delete(_ images: [GalleryImage]) {
        for image in images {
            self.model.images.removeAll(where: { $0 == image })
        }
        self.galleryManager.delete(images: images)
    }
    
    func removeFromAlbum(images: [GalleryImage]) {
        guard albumID != nil else { return }
        
        for image in images {
            model.images.removeAll { $0.fileName == image.fileName}
        }
    }
    
    func addPhotos(images: [GalleryImage]) {
        self.model.images.append(contentsOf: images)
    }
    
    func newThumbnailSize(size: Float) {
        self.model.thumbnailsSize = size
    }
    
    func setAlbumThumbnailImage(image: GalleryImage) {
        if let albumID, var albumIndex = galleryManager.loadAlbumIndex(id: albumID) {
            albumIndex.thumbnail = image.fileName
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func duplicateItem(image: GalleryImage) {
        
    }
    
    func resolveThumbPathFor(image: String) -> String {
        self.pathResolver.resolveThumbPathFor(imageName: image)
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
