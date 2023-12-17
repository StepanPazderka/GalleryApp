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

enum AlbumScreenError {
    case errorDuplicatingImage
    case errorDuplicatingAlbum
}

class AlbumScreenViewModel {
    
    // MARK: -- Properties
    var isEditing = BehaviorRelay(value: false)
    var showingLoading = BehaviorRelay(value: false)
    var errorMessage = BehaviorRelay(value: "")
        
    var albumID: UUID?
    let galleryManager: GalleryManager
    let pathResolver: PathResolver
    
    var importProgress = MutableProgress()
    var filesSelectedInEditMode = [GalleryImage]()
    
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(albumID: UUID? = nil, galleryManager: GalleryManager, pathResolver: PathResolver) {
        self.albumID = albumID
        self.galleryManager = galleryManager
        self.pathResolver = pathResolver
    }
    
    func imagesAsObservable() -> Observable<[GalleryImage]> {
        self.galleryManager.selectedGalleryIndexRelay.map { [weak self] in
            if let albumID = self?.albumID {
                return self?.galleryManager.loadAlbumIndex(with: albumID)?.images ?? [GalleryImage]()
            } else {
                return $0.images
            }
         }
    }
    
    func showingAnnotationsAsObservable() -> Observable<Bool> {
        if let albumID {
            self.galleryManager.loadAlbumIndexAsObservable(id: albumID).map { $0.showingAnnotations ?? false }
        } else {
            self.galleryManager.loadGalleryIndexAsObservable().map { $0.showingAnnotations ?? false }
        }
    }
    
    func updateShowingAnnotations(value: Bool) {
        if let albumID {
            if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
                albumIndex.showingAnnotations = value
                try! self.galleryManager.updateAlbumIndex(index: albumIndex)
            }
        } else {
            if var galleryIndex = self.galleryManager.load(galleryIndex: nil) {
                galleryIndex.showingAnnotations = value
                self.galleryManager.updateGalleryIndex(newGalleryIndex: galleryIndex)
            }
        }
    }
    
    func loadAlbum(by: UUID) -> AlbumIndex? {
        return self.galleryManager.loadAlbumIndex(with: by)
    }
    
    func loadAlbumIndexAsObservable() -> Observable<AlbumIndex> {
        galleryManager.loadAlbumIndexAsObservable(id: albumID!)
    }
    
    func delete(_ images: [GalleryImage]) {
        self.galleryManager.delete(images: images)
    }
    
    func removeFromAlbum(images: [GalleryImage]) {
        guard albumID != nil else { return }
        
        if let albumID {
            if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
                albumIndex.images.removeAll(where: { images.contains($0) })
                try! self.galleryManager.updateAlbumIndex(index: albumIndex)
            }
        }
    }
    
    func addPhotos(images: [GalleryImage]) {
        self.galleryManager.write(images: images)
    }
    
    func newThumbnailSize(size: Float) {
//        self.model.thumbnailsSize = size
    }
    
    func setAlbumThumbnailImage(image: GalleryImage) {
        if let albumID, var albumIndex = galleryManager.loadAlbumIndex(with: albumID) {
            albumIndex.thumbnail = image.fileName
            try! self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func duplicateItem(images: [GalleryImage]) {
        do {
            if let albumID, let albumIndex = loadAlbum(by: albumID) {
                try self.galleryManager.duplicate(images: images, inAlbum: albumIndex)
            } else {
                try self.galleryManager.duplicate(images: images, inAlbum: nil)
            }
        } catch {
            
        }
    }
    
    func resolveThumbPathFor(image: String) -> String {
        self.pathResolver.resolveThumbPathFor(imageName: image)
    }
    
    func handleImportFromFilesApp(urls: [URL]) {
        for url in urls {
            do {
                let filenameExtension = url.pathExtension.lowercased()
                let newFileName = URL(string: UUID().uuidString)!.appendingPathExtension(filenameExtension)
                let targetPath = self.galleryManager.pathResolver.selectedGalleryPath.appendingPathComponent(newFileName.relativeString)
                
                try FileManager.default.moveItem(at: url, to: targetPath)
                let newImage = GalleryImage(fileName: targetPath.lastPathComponent, date: Date(), title: nil)
                self.galleryManager.buildThumbnail(forImage: newImage)
                self.addPhotos(images: [newImage])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func handleImportFromPhotosApp(results: [PHPickerResult]) {
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
                
                let targetPath = self.galleryManager.pathResolver.selectedGalleryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(filenameExtension)
                do {
                    try FileManager.default.moveItem(at: filePath, to: targetPath)
                    newTaskProgress.completedUnitCount = newTaskProgress.totalUnitCount
                    DispatchQueue.main.async {
                        self.galleryManager.buildThumbnail(forImage: GalleryImage(fileName: targetPath.lastPathComponent, date: Date()))
                    }
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
                self.errorMessage.accept("\(NSLocalizedString("kERRORIMPORTINGFILES", comment: "")) \(filenamesThatCouldntBeImported.joined(separator: ", "))")
                stopTimer()
            }
        }
    }
}

