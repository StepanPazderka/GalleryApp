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
import FolderMonitorKit

enum GalleryManagerError: Error {
    case cantStartMonitor
}

class GalleryManager {
    
    // MARK: -- Properties
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var userDefaults: UserDefaults = UserDefaults.standard
    var selectedGalleryPath: URL {
        return libraryPath.appendingPathComponent(selectedGallery)
    }
    var selectedGallery: String
    let settingsManager: SettingsManager
    let fileScannerManager: FileScannerManager
    
    let selectedGalleryIndexRelay = PublishSubject<GalleryIndex>()
    
    
    // MARK: -- Init
    init(settingsManager: SettingsManager, fileScannerManger: FileScannerManager) {
        self.settingsManager = settingsManager
        self.fileScannerManager = fileScannerManger
        
        if let loadedSelectedGallery = userDefaults.string(forKey: kSelectedGallery) {
            selectedGallery = loadedSelectedGallery
        } else {
            selectedGallery = "Default Gallery"
        }
        
        if let galleryIndex = loadGalleryIndex() {
            selectedGalleryIndexRelay.onNext(galleryIndex)
        }
    }
    
    // MARK: -- Basics
    func createAlbum(name: String, parentAlbum: UUID? = nil) throws {
        let albumID = UUID()
        try? FileManager.default.createDirectory(at: selectedGalleryPath.appendingPathComponent(albumID.uuidString), withIntermediateDirectories: true, attributes: nil)
        rebuildAlbumIndex(folder: selectedGalleryPath.appendingPathComponent(albumID.uuidString), albumName: name)
        rebuildGalleryIndex()
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
    
    func addImage(photoID: String, toAlbum: UUID? = nil) {
        if var galleryIndex = self.loadGalleryIndex() {
            galleryIndex.images.append(AlbumImage(fileName: photoID, date: Date()))
            self.rebuildGalleryIndex(gallery: galleryIndex)
        }
        
        if let toAlbum = toAlbum {
            if var album = loadAlbumIndex(id: toAlbum) {
                album.images.append(AlbumImage(fileName: photoID, date: Date()))
                self.updateAlbumIndex(folder: self.selectedGalleryPath, index: album)
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
    
    func lostAllImagesInGalleryFolder() -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []

        let list = fileScannerManager.scanAlbumFolderForImages()
        outputImageList = list
        return outputImageList
    }
    
    func buildThumbs(forAlbum: String) {
        let images = fileScannerManager.scanAlbumFolderForImages(albumName: forAlbum)
        for image in images {
            let newFilename = image.fileName
            let newImage = ImageResizer.resizeImage(image: UIImage(contentsOfFile: selectedGalleryPath.appendingPathComponent(forAlbum).appendingPathComponent(image.fileName).relativePath)!, targetSize: CGSize(width: 300, height: 300))
            if let jpegImage = newImage?.jpegData(compressionQuality: 0.6) {
                if FileManager.default.fileExists(atPath: selectedGalleryPath.appendingPathComponent(forAlbum).appendingPathComponent("thumbs").path) == false {
                    try? FileManager.default.createDirectory(atPath: selectedGalleryPath.appendingPathComponent(forAlbum).appendingPathComponent("thumbs").path, withIntermediateDirectories: false)
                }
                var filePath = selectedGalleryPath.appendingPathComponent(forAlbum).appendingPathComponent("thumbs").appendingPathComponent(newFilename)
                filePath = filePath.deletingPathExtension()
                filePath = filePath.appendingPathExtension("jpg")
                try! jpegImage.write(to: filePath)
            }
        }
    }
    
    static func writeThumb(image: UIImage) {
        
    }
    
    @discardableResult func rebuildAlbumIndex(folder: URL, albumName: String) -> AlbumIndex? {
        let scannedImagesFromFolder = self.fileScannerManager.scanAlbumFolderForImages(albumName: folder.lastPathComponent)
        
        let albumIndex = AlbumIndex(id: UUID(uuidString: folder.lastPathComponent) ?? UUID(), name: albumName, images: scannedImagesFromFolder, thumbnail: scannedImagesFromFolder.first?.fileName ?? "")
        buildThumbs(forAlbum: folder.lastPathComponent)
        let json = try! JSONEncoder().encode(albumIndex)
        try? json.write(to: folder.lastPathComponent == kAlbumIndex ? folder : folder.appendingPathComponent(kAlbumIndex))
        
        return AlbumIndex(from: folder) ?? nil
    }
    
    func updateAlbumIndex(folder: URL, index: AlbumIndex) {
        let json = try! JSONEncoder().encode(index)
        let url = folder.appendingPathComponent(kAlbumIndex)
        try? json.write(to: url)
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
            let albumIndex: AlbumIndex? = self.loadAlbumIndex(id: id)
            let albumMonitor = try! FolderMonitor(url: self.selectedGalleryPath.appendingPathComponent(albumIndex?.id.uuidString ?? UUID().uuidString), trackingEvent: .all, onChange: { [weak self] in
                if let albumIndex = self?.loadAlbumIndex(id: id) {
                    observer.onNext(albumIndex)
                }
            })
            try! albumMonitor.start()
            return Disposables.create {
                albumMonitor.stop()
            }
        }
    }
    
    func loadAlbumIndex(id: UUID) -> AlbumIndex? {
        return scanFolderForAlbums().filter { $0.id == id }.first ?? nil
    }
    
    func loadGalleryIndex(named galleryName: String? = nil) -> GalleryIndex? {
        if FileManager.default.fileExists(atPath: self.selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath) {
            if let GalleryIndexJSON = try? String(contentsOfFile: self.selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath).data(using: .unicode) {
                let decodedGalleryIndex = try! JSONDecoder().decode(GalleryIndex.self, from: GalleryIndexJSON)
                return decodedGalleryIndex
            }
        }
        return nil
    }
    
    func deleteImage(imageName: String) {
        if var galleryIndex = self.loadGalleryIndex() {
            var newImageList = galleryIndex.images
            newImageList.removeAll { AlbumImage in
                AlbumImage.fileName == imageName ? true : false
            }
            galleryIndex.images = newImageList
            do {
                try FileManager.default.removeItem(atPath: self.selectedGalleryPath.appendingPathComponent(imageName).relativePath)
                self.rebuildGalleryIndex()
            } catch {
                
            }
            
        }
    }
    
    func loadGalleryIndex(named: String? = nil) -> Observable<GalleryIndex> {
        return Observable.create { observer in
            var galleryIndexMonitor: FolderMonitor?
            if let galleryIndex = self.loadGalleryIndex() {
                observer.onNext(galleryIndex)
            }
            if !FileManager.default.fileExists(atPath: self.selectedGalleryPath.appendingPathComponent(kGalleryIndex).relativePath) {
                self.rebuildGalleryIndex()
            }
            let url = self.selectedGalleryPath.appendingPathComponent(kGalleryIndex)
            galleryIndexMonitor = try? FolderMonitor(url: url, trackingEvent: .all, onChange: {
                if let galleryIndex = self.loadGalleryIndex() {
                    print("Index changed")
                    observer.onNext(galleryIndex)
                }
            })
            do {
                try galleryIndexMonitor?.start()
            } catch {
                observer.onError(GalleryManagerError.cantStartMonitor)
            }
        
            return Disposables.create {
//                galleryMonitor?.stop()
            }
        }
    }
    
    // MARK: -- Rebuilding Gallery Index
    
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
        
        var newIndex = GalleryIndex(mainGalleryName: selectedGallery, images: self.fileScannerManager.scanAlbumFolderForImages(), albums: scanFolderForAlbums().map { $0.id })
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
        self.selectedGalleryIndexRelay.onNext(newIndex)
        return newIndex
    }
    
    
    @discardableResult func rebuildGalleryIndex(gallery: GalleryIndex) -> GalleryIndex {
        let jsonEncoded = try? JSONEncoder().encode(gallery)
        let url = selectedGalleryPath.appendingPathComponent(kGalleryIndex)
        try? jsonEncoded?.write(to: url)
        
        return GalleryIndex(mainGalleryName: gallery.mainGalleryName, images: self.lostAllImagesInGalleryFolder(), albums: gallery.albums)
    }
}
