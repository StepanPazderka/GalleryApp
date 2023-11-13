//
//  GalleryManagerRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 05.11.2023.
//

import Foundation
import Realm
import RealmSwift
import RxCocoa
import RxSwift

class GalleryManagerRealm: GalleryManager {
    func rebuildGalleryIndex() -> GalleryIndex {
        self.loadGalleryIndex()!
    }
    
    func delete(images: [GalleryImage]) {
        let imagesForDeletion = images.map { GalleryImageRealm(from: $0) }
        
        try! realm.write {
            realm.delete(imagesForDeletion)
        }
    }
    
    func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex {
        let newGalleryIndexRealm = GalleryIndexRealm(from: newGalleryIndex)

        try! realm.write {
            realm.add(newGalleryIndexRealm, update: .modified)
        }
        
        return newGalleryIndex
    }
    
    func buildThumbnail(forImage albumImage: GalleryImage) {
        let images = self.loadGalleryIndex()?.images
        
        let thumbPath = selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(albumImage.fileName).deletingPathExtension().appendingPathExtension(for: .jpeg)
        
        guard !FileManager.default.fileExists(atPath: thumbPath.relativePath) else { return }
        
        guard images != nil else { return }
        
        let image = UIImage(contentsOfFile: selectedGalleryPath.appendingPathComponent(albumImage.fileName).relativePath)
        
        guard let image else { return }
        let resizedImage = ImageResizer.resizeImage(image: image, targetSize: CGSize(width: 300, height: 300))
        guard let resizedImage else { return }
        let jpegImage = resizedImage.jpegData(compressionQuality: 0.6)
        if !FileManager.default.fileExists(atPath: selectedGalleryPath.appendingPathComponent(kThumbs).relativePath) {
            try? FileManager.default.createDirectory(at: selectedGalleryPath.appendingPathComponent(kThumbs), withIntermediateDirectories: false)
        }
        
        try? jpegImage?.write(to: thumbPath)
    }
    
    func loadAlbumIndexAsObservable(id: UUID) -> RxSwift.Observable<AlbumIndex> {
        return Observable.create { [weak self] observer in
            let fetchedAlbum = self?.realm.objects(AlbumIndexRealm.self).first(where: {
                $0.id == id.uuidString
            })
            if let fetchedAlbum {
                observer.onNext(AlbumIndex(from: fetchedAlbum))
            }
            
            return Disposables.create {}
        }
    }
    
    func delete(gallery: String) {
        try! realm.write {
            let gallery = realm.objects(GalleryIndexRealm.self).where {
                $0.name == gallery
            }
            
            try! realm.write {
                realm.delete(gallery)
            }
        }
    }
    
    func duplicateAlbum(index: AlbumIndex) -> AlbumIndex {
        let fetchedAlbum = realm.objects(AlbumIndexRealm.self).first(where: { $0.id == index.name })
        
        if let fetchedAlbum {
            var newAlbum = fetchedAlbum
            newAlbum.id = UUID().uuidString
            
            try! realm.write {
                realm.add(newAlbum)
            }
            
            return AlbumIndex(from: newAlbum)
        }
        
        return index
    }
    
    func loadGalleryIndex() -> GalleryIndex? {
        realm.objects(GalleryIndexRealm.self).first(where: { [weak self] in
            $0.name == self?.settingsManager.selectedGallery
        }).map { GalleryIndex(from: $0) }
    }
    
    func loadAlbumIndex(id: UUID) -> AlbumIndex? {
        realm.objects(AlbumIndexRealm.self).first { albumIndex in
            albumIndex.id == id.uuidString
        }.map { AlbumIndex(from: $0) }
    }
    
    func loadAlbumImage(id: String) -> GalleryImage? {
        return realm.objects(GalleryImageRealm.self).first(where: {
            $0.id == id
        }).map { GalleryImage(from: $0) }
    }
    
    func update(image: GalleryImage) {
        let newGalleryImageRealm = GalleryImageRealm(from: image)
        
        try! realm.write {
            realm.add(newGalleryImageRealm, update: .modified)
        }
    }
    
    func resolveThumbPathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
    }
    
    func resolvePathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
    
    
    // MARK: - Properties
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var selectedGalleryPath: URL {
        get {
            return libraryPath.appendingPathComponent(settingsManager.selectedGallery)
        }
    }
    
    let realm = try! Realm()
    
    let settingsManager: SettingsManager
    let fileScannerManager: FileScannerManager
    
    public let selectedGalleryIndexRelay = BehaviorRelay<GalleryIndex>(value: .empty)
    private var model: GalleryIndex {
        didSet {
            self.selectedGalleryIndexRelay.accept(model)
            self.updateModel(model: model)
        }
    }
    
    init(settingsManager: SettingsManager, fileScannerManger: FileScannerManager) {
        
        self.settingsManager = settingsManager
        self.fileScannerManager = fileScannerManger
        
        self.model = .empty
        
        writeTestData()
        loadData()
    }
    
    func updateModel(model: GalleryIndex) {
        let indexes = realm.objects(GalleryIndexRealm.self).filter("name = %@", self.settingsManager.selectedGallery)
        
        if let index = indexes.first {
            try! realm.write {
                let updatedIndex = GalleryIndexRealm(from: model)
                realm.add(updatedIndex, update: .modified)
            }
        }
    }
    
    func loadData() {
        let index = realm.objects(GalleryIndexRealm.self).where { [weak self] in
            $0.name == self!.settingsManager.selectedGallery
        }.first!
        
        self.model = GalleryIndex(from: index)
    }
    
    func writeTestData() {
        let galleryIndexRealmTestObject = GalleryIndexRealm(name: settingsManager.selectedGallery, thumbnailSize: 200, showingAnnotations: false)
        
        try! realm.write {
            realm.add(galleryIndexRealmTestObject)
        }
    }
    
    func galleryObservable() -> Observable<GalleryIndex> {
        self.selectedGalleryIndexRelay.asObservable()
    }
    
    func removeAlbum(AlbumName: String) {
        do {
            try FileManager.default.removeItem(atPath: selectedGalleryPath.appendingPathComponent(AlbumName).path)
        } catch {
            print("Error while removing album: \(error)")
        }
    }
    
    func delete(album: UUID) {
        
    }
    
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> ())?) throws {
        
    }
    
    func updateAlbumIndex(index: AlbumIndex) {
        
        try! realm.write {
            let updatedIndex = AlbumIndexRealm(from: index)
            
            realm.add(updatedIndex, update: .modified)
        }
    }
}
