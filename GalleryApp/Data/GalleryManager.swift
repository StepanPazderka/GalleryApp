//
//  MainIndexManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import RxSwift
import RxCocoa

enum MoveImageError: Error {
    case imageAlreadyInAlbum
}

class GalleryManager {
    
    // MARK: - Properties
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var userDefaults: UserDefaults = UserDefaults.standard
    var selectedGalleryPath: URL {
        get {
            return libraryPath.appendingPathComponent(settingsManager.selectedGallery)
        }
    }
    let settingsManager: SettingsManager
    let fileScannerManager: FileScannerManager
    
    let selectedGalleryIndexRelay = BehaviorRelay<GalleryIndex>(value: .empty)
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(settingsManager: SettingsManager, fileScannerManger: FileScannerManager) {
        self.settingsManager = settingsManager
        self.fileScannerManager = fileScannerManger
        
        if let galleryIndex = loadGalleryIndex() {
            selectedGalleryIndexRelay.accept(galleryIndex)
        }
        
        self.settingsManager.selectedGalleryAsObservable.subscribe(onNext: { selectedGalleryName in
            let galleryIndex: GalleryIndex? = self.loadGalleryIndex()
            if let galleryIndex {
                self.selectedGalleryIndexRelay.accept(galleryIndex)
            } else {
                self.rebuildGalleryIndex()
            }
        }).disposed(by: disposeBag)
        
        self.monitorGalleryIndexChanges()
    }
    
    func monitorGalleryIndexChanges() {
        self.selectedGalleryIndexRelay.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] galleryIndex in
            self?.updateGalleryIndex(newGalleryIndex: galleryIndex)
        }).disposed(by: disposeBag)
    }
    
    func galleryObservable() -> Observable<GalleryIndex> {
        Observable.create { observer -> Disposable in
            let galleryIndex: GalleryIndex? = self.loadGalleryIndex()
            if let galleryIndex {
                observer.onNext(galleryIndex)
            }
            
            return Disposables.create {}
        }
    }
    
    // MARK: - Essentials
    func createAlbum(name: String, parentAlbum: UUID? = nil) throws {
        let albumID = UUID()
        try? FileManager.default.createDirectory(at: selectedGalleryPath.appendingPathComponent(albumID.uuidString), withIntermediateDirectories: true, attributes: nil)
        rebuildAlbumIndex(folder: selectedGalleryPath.appendingPathComponent(albumID.uuidString), albumName: name)
        if var galleryIndex = loadGalleryIndex() {
            galleryIndex.albums.append(albumID)
            self.selectedGalleryIndexRelay.accept(galleryIndex)
        }
    }
    
    /// Duplicates provided AlbumIndex int a new Album
    @discardableResult func dubplicateAlbum(index: AlbumIndex) -> AlbumIndex {
        var newAlbumIndex = index
        newAlbumIndex.id = UUID()
        newAlbumIndex.name = newAlbumIndex.name + " " + NSLocalizedString("kCOPY", comment: "a copy")
        let newAlbumPath = selectedGalleryPath.appendingPathComponent(newAlbumIndex.id.uuidString)
        try? FileManager.default.createDirectory(at: newAlbumPath, withIntermediateDirectories: true, attributes: nil)
        if let json = try? JSONEncoder().encode(newAlbumIndex) {
            try? json.write(to: newAlbumPath.appendingPathComponent(kAlbumIndex))
        }
        rebuildGalleryIndex()
        
        return newAlbumIndex
    }
    
    func delete(album: UUID) {
        do {
            try FileManager.default.removeItem(at: selectedGalleryPath.appendingPathComponent(album.uuidString))
            self.rebuildGalleryIndex()
        } catch {
            print(error)
        }
    }
    
    func scanFolderForAlbums(url: URL? = nil) -> [AlbumIndex] {
        var detectedAlbums = [URL]()
        
        if let enumerator = FileManager.default.enumerator(at: url ?? selectedGalleryPath, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        detectedAlbums.append(fileURL)
                    }
                } catch { print(error, fileURL) }
            }
        }
        
        return detectedAlbums
            .filter { $0.lastPathComponent == kAlbumIndex }
            .compactMap { AlbumIndex(from: $0) ?? rebuildAlbumIndex(folder: $0, albumName: "Rebuilded Album")}
    }
    
    func removeAlbum(AlbumName: String) {
        do {
            try FileManager.default.removeItem(atPath: selectedGalleryPath.appendingPathComponent(AlbumName).path)
        } catch {
            print("Error while removing album: \(error)")
        }
    }
    
    func move(Image: AlbumImage, toAlbum: UUID, callback: (() -> ())? = nil) throws {
        guard let targetAlbumIndex = loadAlbumIndex(id: toAlbum) else { return }
        var newIndex = targetAlbumIndex
        for albumImage in targetAlbumIndex.images {
            if albumImage.fileName == Image.fileName {
                throw MoveImageError.imageAlreadyInAlbum
            }
        }
        newIndex.images.append(Image)
        self.updateAlbumIndex(index: newIndex)
        if let callback = callback {
            callback()
        }
    }
    
    func addImage(photoID: String, toAlbum: UUID? = nil) {
        if var galleryIndex = self.loadGalleryIndex() {
            galleryIndex.images.append(AlbumImage(fileName: photoID, date: Date()))
            self.rebuildGalleryIndex()
            self.selectedGalleryIndexRelay.accept(galleryIndex)
        }
        
        if let toAlbum = toAlbum {
            if var album = loadAlbumIndex(id: toAlbum) {
                album.images.append(AlbumImage(fileName: photoID, date: Date()))
                self.updateAlbumIndex(index: album)
            }
        }
    }
    
    func addImages(photos: [String], toAlbum: UUID? = nil) {
        if var galleryIndex = self.loadGalleryIndex() {
            galleryIndex.images.append(contentsOf: photos.map { AlbumImage(fileName: $0, date: Date()) })
            self.rebuildGalleryIndex(gallery: galleryIndex)
            self.selectedGalleryIndexRelay.accept(galleryIndex)
        }
        
        if let toAlbum = toAlbum {
            if var album = loadAlbumIndex(id: toAlbum) {
                album.images.append(contentsOf: photos.map { AlbumImage(fileName: $0, date: Date()) })
                self.updateAlbumIndex(index: album)
            }
        }
    }
    
    func loadImage() -> UIImage {
        let outputImage: UIImage = UIImage()
        return outputImage
    }
    
    func moveImagesFromAlbumFoldersToMainGalleryFolder() {
        let albumNames = scanFolderForAlbums(url: selectedGalleryPath).map { albumIndex in
            albumIndex.name
        }
        
        var imageURLs = [URL]()
        for albumName in albumNames {
            let images = fileScannerManager.scanAlbumFolderForImages(albumName: albumName)
            let newImageURLs = images.map { imageName in
                return selectedGalleryPath.appendingPathComponent(albumName).appendingPathComponent(imageName.fileName)
            }
            imageURLs.append(contentsOf: newImageURLs)
        }
        
        for url in imageURLs {
            do {
                try FileManager.default.moveItem(at: url, to: selectedGalleryPath.appendingPathComponent(url.lastPathComponent))
            } catch {
                
            }
        }
    }
    
    func scanGalleryFolderForImages() -> [URL] {
        var outputImageList = [URL]()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: selectedGalleryPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                .filter { $0.pathExtension == "jpeg" }
            outputImageList = files.map {
                return $0
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return outputImageList
    }
    
    func listAllImagesInGalleryFolder() -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []
        
        let list = fileScannerManager.scanAlbumFolderForImages()
        outputImageList = list
        return outputImageList
    }
    
    func buildThumbs(forAlbum: String) {
        let images = self.loadGalleryIndex()?.images
        
        guard let images else { return }
        
        for image in images {
            let newFilename = image.fileName
            let newImage = ImageResizer.resizeImage(image: UIImage(contentsOfFile: selectedGalleryPath.appendingPathComponent(image.fileName).relativePath)!, targetSize: CGSize(width: 300, height: 300))
            if let jpegImage = newImage?.jpegData(compressionQuality: 0.6) {
                if FileManager.default.fileExists(atPath: selectedGalleryPath.appendingPathComponent(kThumbs).path) == false {
                    try? FileManager.default.createDirectory(atPath: selectedGalleryPath.appendingPathComponent(kThumbs).path, withIntermediateDirectories: false)
                }
                var filePath = selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(newFilename)
                filePath = filePath.deletingPathExtension()
                filePath = filePath.appendingPathExtension("jpg")
                try! jpegImage.write(to: filePath)
            }
        }
    }
    
    func buildThumb(forImage albumImage: AlbumImage) {
        let images = self.loadGalleryIndex()?.images
        
        let thumbPath = selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(albumImage.fileName).deletingPathExtension().appendingPathExtension("jpg")
        
        guard !FileManager.default.fileExists(atPath: thumbPath.relativePath) else { return }
        
        guard let images else { return }
        
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
    
    static func writeThumb(image: UIImage) {
        
    }
    
    @discardableResult func rebuildAlbumIndex(folder: URL, albumName: String) -> AlbumIndex? {
        let scannedImagesFromFolder = self.fileScannerManager.scanAlbumFolderForImages(albumName: folder.lastPathComponent)
        
        let albumIndex = AlbumIndex(id: UUID(uuidString: folder.lastPathComponent) ?? UUID(), name: albumName, images: scannedImagesFromFolder, thumbnail: scannedImagesFromFolder.first?.fileName ?? "")
        let json = try! JSONEncoder().encode(albumIndex)
        try? json.write(to: folder.lastPathComponent == kAlbumIndex ? folder : folder.appendingPathComponent(kAlbumIndex))
        
        return AlbumIndex(from: folder) ?? nil
    }
    
    func updateAlbumIndex(folder: URL, index: AlbumIndex) {
        let json = try! JSONEncoder().encode(index)
        let url = folder.appendingPathComponent(kAlbumIndex)
        try? json.write(to: url)
    }
    
    /**
    Rewrites Album Index in file system
     */
    func updateAlbumIndex(index: AlbumIndex) {
        let json = try! JSONEncoder().encode(index)
        let url = self.selectedGalleryPath.appendingPathComponent(index.id.uuidString).appendingPathComponent(kAlbumIndex)
        try? json.write(to: url)
        if let galleryIndex: GalleryIndex = loadGalleryIndex() {
            self.selectedGalleryIndexRelay.accept(galleryIndex)
        }
        
    }
    
    func loadAlbumIndex(folder: URL) throws -> AlbumIndex? {
        let indexPath = folder.lastPathComponent == kAlbumIndex ? folder.relativePath : folder.appendingPathComponent(kAlbumIndex).relativePath

        let jsonDATA = try? String(contentsOfFile: indexPath).data(using: .unicode)
        if let jsonData = jsonDATA {
            let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData)
            guard (decodedData != nil) else { rebuildAlbumIndex(folder: folder, albumName: "Rebuilded Album"); return decodedData }
            if var decodedData = decodedData {
                if decodedData.images.isEmpty {
                    decodedData.images = fileScannerManager.scanAlbumFolderForImages(albumName: folder.absoluteString)
                    return decodedData
                }
            }
            return decodedData
        }
        return nil
    }
    
    func loadAlbumIndex(id: UUID) -> Observable<AlbumIndex> {
        return Observable.create { observer in
            if let albumIndex = self.loadAlbumIndex(id: id) {
                observer.onNext(albumIndex)
            }
            return Disposables.create {
            }
        }
    }
    
    func loadAlbumIndex(id: UUID) -> AlbumIndex? {
        return scanFolderForAlbums().filter { $0.id == id }.first ?? nil
    }
    
    func loadAlbumImage(id: String) -> AlbumImage? {
        let index: GalleryIndex? = loadGalleryIndex()
        let image = index?.images.first(where: { image in
            image.fileName == id
        })
        return image
    }
    
    func loadGalleryIndex(named galleryName: String? = nil) -> GalleryIndex? {
        if FileManager.default.fileExists(atPath: self.selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath) {
            if let encodedGalleryIndex = try? String(contentsOfFile: self.selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath).data(using: .unicode) {
                let decodedGalleryIndex = try? JSONDecoder().decode(GalleryIndex.self, from: encodedGalleryIndex)
                return decodedGalleryIndex
            }
        }
        return nil
    }
    
    func delete(images: [String]) {
        if var galleryIndex = self.loadGalleryIndex() {
            for name in images {
                galleryIndex.images.removeAll { image in
                    image.fileName == name
                }
            }
            
            updateGalleryIndex(newGalleryIndex: galleryIndex)
            for image in images {
                do {
                    try FileManager.default.removeItem(atPath: self.selectedGalleryPath.appendingPathComponent(image).relativePath)
                } catch {
                    
                }
            }
        }
    }
    
    // MARK: - Update Album Image
    func updateAlbumImage(image: AlbumImage) {
        if var index = loadGalleryIndex() {
            if let element = index.images.firstIndex(where: { AlbumImage in
                AlbumImage.id == image.id
            }) {
                index.images[element] = image
                updateGalleryIndex(newGalleryIndex: index)
            }
        }
    }
    
    // MARK: - Update Gallery Index
    @discardableResult func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex {
        let newIndex = newGalleryIndex
        let galleryIndexPath = selectedGalleryPath.appendingPathComponent(kGalleryIndex)
        
        let jsonEncoded = try? JSONEncoder().encode(newIndex)
        try! jsonEncoded?.write(to: galleryIndexPath)
        self.selectedGalleryIndexRelay.accept(newIndex)
        
        return newIndex
    }
    
    // MARK: - Rebuilding Gallery Index
    /**
        Will rebuild gallery index based on files in Gallery folder
     */
    @discardableResult func rebuildGalleryIndex() -> GalleryIndex {
        var oldAlbums: [UUID] = [UUID]()
        
        if FileManager.default.fileExists(atPath: selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath) {
            if let oldIndex = loadGalleryIndex(named: nil) {
                oldAlbums = oldIndex.albums
            }
        }
        
        var newIndex = GalleryIndex(mainGalleryName: settingsManager.selectedGallery, images: self.fileScannerManager.scanAlbumFolderForImages(), albums: scanFolderForAlbums().map { $0.id })
        var newAlbums = scanFolderForAlbums().map { $0.id }

        oldAlbums.append(contentsOf: newAlbums.removingDuplicates())
        
        let combinedAlbums: [UUID] = oldAlbums.removingDuplicates()
        
        newIndex.albums = combinedAlbums.filter { loadAlbumIndex(id: $0) != nil }
        
        let jsonEncoded = try? JSONEncoder().encode(newIndex)
        let url = selectedGalleryPath.appendingPathComponent(kGalleryIndex)
        if !FileManager.default.fileExists(atPath: selectedGalleryPath.relativePath) {
            try? FileManager.default.createDirectory(at: selectedGalleryPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        try! jsonEncoded?.write(to: url)
        self.selectedGalleryIndexRelay.accept(newIndex)
        return newIndex
    }
    
    @discardableResult func rebuildGalleryIndex(gallery: GalleryIndex) -> GalleryIndex {
        let jsonEncoded = try? JSONEncoder().encode(gallery)
        let url = selectedGalleryPath.appendingPathComponent(kGalleryIndex)
        try? jsonEncoded?.write(to: url)
        
        return GalleryIndex(mainGalleryName: gallery.mainGalleryName, images: self.listAllImagesInGalleryFolder(), albums: gallery.albums)
    }
    
    func resolvePathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
    
    func resolveThumbPathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension("jpg").relativePath
    }
}
