//
//  GalleryManagerRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 05.11.2023.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import RxRealm

class GalleryManagerImpl: GalleryManager {

    // MARK: - Protocol Properties
    let settingsManager: SettingsManager
    let fileScannerManager: FileScannerManager
    let pathResolver: PathResolver
    let disposeBag: DisposeBag = DisposeBag()
    
    // MARK: - Custom Properties
    let realm: Realm?
    
    public let selectedGalleryIndexRelay = BehaviorRelay<GalleryIndex>(value: .empty)
    
    // MARK: - Init
    init(settingsManager: SettingsManager, fileScannerManger: FileScannerManager, pathResolver: PathResolver, isTesting: Bool) {
        self.settingsManager = settingsManager
        self.fileScannerManager = fileScannerManger
        self.pathResolver = pathResolver
                
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        
        do {
            if isTesting {
                let inMemoryRealmConfig = Realm.Configuration(inMemoryIdentifier: "MyInMemoryRealm")
                self.realm = try Realm(configuration: inMemoryRealmConfig)
            } else {
                self.realm = try Realm()
            }
        } catch {
            print("Error: \(error)")
            self.realm = nil
        }
        
        self.loadGalleryIndexAsObservable().subscribe(onNext: { galleryIndex in
            self.selectedGalleryIndexRelay.accept(galleryIndex)
        }).disposed(by: disposeBag)
    }
    
    func loadImageAsObservable(with id: UUID) -> Observable<GalleryImage> {
        let results = realm?.objects(GalleryImageRealm.self).first {
            $0.id == id.uuidString
        }
        
        if let results {
            return Observable.from(object: results).map { GalleryImage(from: $0) }
        } else {
            return Observable.just(.empty)
        }
    }
    
    func loadAlbumIndex(with id: UUID) -> AlbumIndex? {
        realm?.objects(AlbumIndexRealm.self).first { albumIndex in
            albumIndex.id == id.uuidString
        }.map { AlbumIndex(from: $0) }
    }
    
    func load(galleryIndex: String? = nil) -> GalleryIndex? {
        var fetchedIndex: GalleryIndexRealm?

        fetchedIndex = self.realm?.objects(GalleryIndexRealm.self).first(where: { [weak self] in
            $0.name == self?.settingsManager.selectedGalleryName
        })
        
        return fetchedIndex.map { GalleryIndex(from: $0) }
    }
        
    func loadAlbumIndexAsObservable(id: UUID) -> Observable<AlbumIndex> {
        let results = realm?.objects(AlbumIndexRealm.self).first {
            $0.id == id.uuidString
        }
        
        if let results {
            return Observable.from(object: results).map { AlbumIndex(from: $0) }
        } else {
            return Observable.just(.empty)
        }
    }

    func persistNewGalleryIndex(withName name: String) {
        let newGalleryIndexForRealm = GalleryIndexRealm(name: name, thumbnailSize: 200, showingAnnotations: false)
        guard let realm else { return }
        do {
            try realm.write {
                realm.add(newGalleryIndexForRealm)
            }
        } catch {
            print("An error occurred while writing to Realm: \(error)")
        }
        
        if !FileManager.default.fileExists(atPath: pathResolver.selectedGalleryPath.relativePath) {
            try? FileManager.default.createDirectory(at: pathResolver.selectedGalleryPath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    @discardableResult func createAlbum(name: String, parentAlbum: UUID?) throws -> AlbumIndex {
        let newAlbumIndex = AlbumIndexRealm(name: name)
        
        var galleryIndex = load()
        galleryIndex?.albums.append(AlbumIndex(from: newAlbumIndex).id)
        
        try! realm?.write {
            if let galleryIndex {
                let galleryRealmInstance = GalleryIndexRealm(from: galleryIndex)
                galleryRealmInstance.albums.append(newAlbumIndex)
                
                realm?.add(galleryRealmInstance, update: .modified)
            }
        }
        
        return AlbumIndex(from: newAlbumIndex)
    }
    
    func delete(images: [GalleryImage]) {
        guard let realm = realm else { return }

        let imageIDs = images.map { $0.id.uuidString }

        do {
            try realm.write {
                let imagesToDelete = realm.objects(GalleryImageRealm.self).filter("id IN %@", imageIDs)
                realm.delete(imagesToDelete)
                for image in images {
                    let fullImagePath = self.pathResolver.resolvePathFor(imageName: image.fileName)
                    let thumbImagePath = self.pathResolver.resolveThumbPathFor(imageName: image.fileName)
                    
                    try! FileManager.default.removeItem(atPath: fullImagePath)
                    try! FileManager.default.removeItem(atPath: thumbImagePath)
                }
            }
        } catch {
            print("Error deleting images: \(error)")
        }
    }
    
    func write(images: [GalleryImage]) {
        let galleryImagesForRealm = images.map { GalleryImageRealm(from: $0) }
         
        do {
            try realm?.write {
                if let index = load() {
                    let indexForRealm = GalleryIndexRealm(from: index)
                    indexForRealm.images.append(objectsIn: galleryImagesForRealm)
                    realm?.add(indexForRealm, update: .modified)
                }
                
                realm?.add(galleryImagesForRealm)
            }
        } catch {
            print(error)
        }
    }
    
    func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex {
        let newGalleryIndexRealm = GalleryIndexRealm(from: newGalleryIndex)

        try! realm?.write {
            realm?.add(newGalleryIndexRealm, update: .modified)
        }
        
        return newGalleryIndex
    }
    
    func buildThumbnail(forImage albumImage: GalleryImage) {
        let images = self.load()?.images
        
        let thumbPath = pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(albumImage.fileName).deletingPathExtension().appendingPathExtension(for: .jpeg)
        
        guard !FileManager.default.fileExists(atPath: thumbPath.relativePath) else { return }
        
        guard images != nil else { return }
        
        let image = UIImage(contentsOfFile: pathResolver.selectedGalleryPath.appendingPathComponent(albumImage.fileName).relativePath)
        
        guard let image else { return }
        let resizedImage = ImageResizer.resizeImage(image: image, targetSize: CGSize(width: 300, height: 300))
        guard let resizedImage else { return }
        let jpegImage = resizedImage.jpegData(compressionQuality: 0.6)
        if !FileManager.default.fileExists(atPath: pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).relativePath) {
            try? FileManager.default.createDirectory(at: pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs), withIntermediateDirectories: false)
        }
        
        try? jpegImage?.write(to: thumbPath)
    }
    
    func delete(gallery: String) {
        try! realm?.write {
            let gallery = realm?.objects(GalleryIndexRealm.self).where {
                $0.name == gallery
            }
            
            if let gallery {
                try! realm?.write {
                    realm?.delete(gallery)
                }
            }
        }
    }
    
    @discardableResult func duplicate(album: AlbumIndex) -> AlbumIndex {
        guard let fetchedAlbum = realm?.objects(AlbumIndexRealm.self).first(where: { $0.id == album.id.uuidString }) else { return album }
        
        var newAlbum = AlbumIndexRealm(id: UUID().uuidString, name: fetchedAlbum.name, thumbnail: fetchedAlbum.thumbnail, images: fetchedAlbum.images)
                    
        if let index = load() {
            try! realm?.write {
                var updatedIndex = GalleryIndexRealm(from: index)
                updatedIndex.albums.append(newAlbum)
                realm?.add(updatedIndex, update: .modified)
                
                realm?.add(newAlbum)
            }
        }
        
        return AlbumIndex(from: newAlbum)
    }
    
    func update(image: GalleryImage) {
        let newGalleryImageRealm = GalleryImageRealm(from: image)
        
        do {
            try realm?.write {
                realm?.add(newGalleryImageRealm, update: .modified)
            }
        } catch {
            print("Some error while trying to persist data: \(error)")
        }
    }
    
    func resolveThumbPathFor(imageName: String) -> String {
        return self.pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
    }
    
    func resolvePathFor(imageName: String) -> String {
        return self.pathResolver.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
    
    func remove(image: GalleryImage, from album: AlbumIndex) {
        let imageForRealm = GalleryImageRealm(from: image)
        var albumIndexRealm = AlbumIndexRealm(from: album)
        let index = albumIndexRealm.images.firstIndex(where: { $0 == imageForRealm })
        if let index {
            albumIndexRealm.images.remove(at: index)
            
            try! realm?.write {
                realm?.add(albumIndexRealm, update: .modified)
            }
        }
    }
    
    func removeAlbum(AlbumName: String) {
        do {
            try FileManager.default.removeItem(atPath: pathResolver.selectedGalleryPath.appendingPathComponent(AlbumName).path)
        } catch {
            print("Error while removing album: \(error)")
        }
    }
    
    func delete(album: UUID) {
        let albumForDeletion = realm?.objects(AlbumIndexRealm.self).filter("id == %@", album.uuidString)
        
        if let albumForDeletion {
            try! realm?.write {
                realm?.delete(albumForDeletion)
            }
        }
    }
    
    func duplicate(images: [GalleryImage], inAlbum album: AlbumIndex?) throws {
        var imagesForRealm = images.map { galleryImage in
            var imageForRealm = GalleryImageRealm(from: galleryImage)
            imageForRealm.id = UUID().uuidString
            return imageForRealm
        }
        
        if let index = load(galleryIndex: nil) {
            var indexForRealm = GalleryIndexRealm(from: index)
            indexForRealm.images.append(objectsIn: imagesForRealm)
            
            do {
                try realm?.write {
                    
                    if let album {
                        var albumIndexForRealm = AlbumIndexRealm(from: album)
                        albumIndexForRealm.images.append(objectsIn: imagesForRealm)
                        realm?.add(albumIndexForRealm)
                    }
                    
                    realm?.add(imagesForRealm)
                    realm?.add(indexForRealm, update: .modified)
                }
            } catch {
                throw error
            }
        }
    }
    
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> ())?) throws {
        var album = self.loadAlbumIndex(with: toAlbum)
        if var album {
            if !album.images.contains(Image) {
                album.images.append(Image)
            }
            try? realm?.write {
                let albumIndexRealm = AlbumIndexRealm(from: album)
                realm?.add(albumIndexRealm, update: .modified)
            }
        }
    }
    
    @discardableResult func updateAlbumIndex(index: AlbumIndex) throws -> AlbumIndex {
        do {
            try realm?.write {
                let updatedIndex = AlbumIndexRealm(from: index)
                
                realm?.add(updatedIndex, update: .modified)
            }
        } catch {
            throw error
        }
        
        if let updatedAlbumFromDatabse = realm?.objects(AlbumIndexRealm.self).filter("id == %@", index.id.uuidString).first {
            return AlbumIndex(from: updatedAlbumFromDatabse)
        } else {
            throw GalleryManagerError.cantReadAlbum
        }
    }
}

extension GalleryManagerImpl {
    func loadGalleryIndexAsObservable() -> Observable<GalleryIndex> {
        let selectedGalleryName = self.settingsManager.selectedGalleryName
        
        var galleryIndexesFromDatabase = realm?.objects(GalleryIndexRealm.self)
        
        if let galleryIndexesFromDatabase {
            return Observable.collection(from: galleryIndexesFromDatabase).map { $0.first ?? GalleryIndexRealm() }.map { GalleryIndex(from: $0) }.filter { $0.mainGalleryName == selectedGalleryName }
        } else {
            return Observable.empty()
        }
    }
}