//
//  MainIndexManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class GalleryManager {
    var config: Config
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var userDefaults: UserDefaults = UserDefaults.standard
    var selectedGalleryPath: URL
    
    init(config: Config) {
        self.config = config
        self.selectedGalleryPath = config.libraryPath.appendingPathComponent(config.selectedGallery)
        moveImagesFromAlbumFoldersToMainGalleryFolder()
        loadLastSettings()
    }
    
    func loadLastSettings() {
        var selectedGallery = userDefaults.string(forKey: "selectedGallery")
        print("Selected Gallery: \(selectedGallery)")
    }
    
    func createAlbum(name: String, parentAlbum: URL? = nil) throws {
        if let parentAlbum = parentAlbum {
            try? FileManager.default.createDirectory(at: selectedGalleryPath.appendingPathComponent(parentAlbum.relativeString).appendingPathComponent(name), withIntermediateDirectories: true, attributes: nil)
            rebuildAlbumIndex(folder: selectedGalleryPath.appendingPathComponent(parentAlbum.relativeString).appendingPathComponent(name))
        } else {
            try? FileManager.default.createDirectory(at: selectedGalleryPath.appendingPathComponent(name), withIntermediateDirectories: true, attributes: nil)
            rebuildAlbumIndex(folder: selectedGalleryPath.appendingPathComponent(name))
        }
    }

    func listAlbums(url: URL?) -> [AlbumIndex] {
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(at: url ?? selectedGalleryPath, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        files.append(fileURL)
                    }
                } catch { print(error, fileURL) }
            }
        }
        
        var listedAlbums = [AlbumIndex]()
        listedAlbums = files
            .filter { $0.lastPathComponent == "index.json" }
            .map { AlbumIndex(from: $0) ?? rebuildAlbumIndex(folder: $0) }
    
        return listedAlbums
    }
    
    func removeAlbum(AlbumName: String) {
        do {
            try FileManager.default.removeItem(atPath: selectedGalleryPath.appendingPathComponent(AlbumName).path)
        } catch {
            print("Error while removing album: \(error)")
        }
    }
    
    func addImage(photoID: UUID, toAlbum: String) {
        do {
            let albumIndex = try loadAlbumIndex(folder: URL(string: toAlbum)!)
            if var albumIndex = albumIndex {
                albumIndex.images.append(AlbumImage(fileName: photoID.uuidString, date: Date()))
                self.updateAlbumIndex(folder: URL(string: toAlbum)!, index: albumIndex)
            }
        } catch {
            
        }
        
    }
    
    func loadImage() -> UIImage {
        let outputImage: UIImage = UIImage()
        return outputImage
    }
    
    func scanFolderForImages(album: String) -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []
        
        do {
            var files: [URL] = [URL]()
            files = try FileManager.default.contentsOfDirectory(at: selectedGalleryPath.appendingPathComponent(album), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]).filter { $0.pathExtension == "jpeg" }
            outputImageList = files.map {
                var fileAttributes = try? FileManager.default.attributesOfItem(atPath: $0.path)
                
                return AlbumImage(fileName: $0.lastPathComponent,
                                  date: fileAttributes?[.creationDate] as? Date ?? Date())
                
            }
        } catch {
            print(error.localizedDescription)
        }
        return outputImageList
    }
    
    func moveImagesFromAlbumFoldersToMainGalleryFolder() {
        let albumNames = listAlbums(url: selectedGalleryPath).map { albumIndex in
            albumIndex.name
        }
        
        var imageURLs = [URL]()
        for albumName in albumNames {
            let images = scanFolderForImages(album: albumName)
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
    
    func listAllImages() -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []
        let indexes = listAlbums(url: nil)
        
        do {
            var files: [URL] = [URL]()
            files = try FileManager.default.contentsOfDirectory(at: selectedGalleryPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]).filter { $0.pathExtension == "jpeg" }
            outputImageList = files.map {
                var fileAttributes = try? FileManager.default.attributesOfItem(atPath: $0.path)
                
                return AlbumImage(fileName: $0.lastPathComponent,
                                  date: fileAttributes?[.creationDate] as? Date ?? Date())
                }
        } catch {
            print(error.localizedDescription)
        }
        
        return outputImageList
    }
    
    func buildThumbs(forAlbum: String) {
        let images = scanFolderForImages(album: forAlbum)
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
    
    @discardableResult func rebuildAlbumIndex(folder: URL) -> AlbumIndex {
        let jsonTest = AlbumIndex(name: folder.lastPathComponent, images: self.scanFolderForImages(album: folder.lastPathComponent), thumbnail: self.scanFolderForImages(album: folder.lastPathComponent).first?.fileName ?? "")
        buildThumbs(forAlbum: folder.lastPathComponent)
        let json = try! JSONEncoder().encode(jsonTest)
        try? json.write(to: folder.lastPathComponent == "index.json" ? folder : folder.appendingPathComponent("index.json"))
        
        return AlbumIndex(from: folder)!
    }
    
    @discardableResult func rebuildGalleryIndex(gallery: GalleryIndex) -> GalleryIndex {
        let jsonEncoded = try? JSONEncoder().encode(gallery)
        let url = selectedGalleryPath.appendingPathComponent("index.json")
        try? jsonEncoded?.write(to: url)
        
        return GalleryIndex(mainGalleryName: gallery.mainGalleryName, albums: gallery.albums)
    }
    
    func updateAlbumIndex(folder: URL, index: AlbumIndex) {
        let json = try! JSONEncoder().encode(index)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    func loadAlbumIndex(folder: URL) throws -> AlbumIndex? {
        let indexPath = folder.lastPathComponent == "index.json" ? folder.relativePath : folder.appendingPathComponent("index.json").relativePath
        if !FileManager.default.fileExists(atPath: indexPath) {
            rebuildAlbumIndex(folder: folder)
        }
        let jsonDATA = try? String(contentsOfFile: indexPath).data(using: .unicode)
        if let jsonData = jsonDATA {
            let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData)
            guard (decodedData != nil) else { rebuildAlbumIndex(folder: folder); return decodedData }
            if var decodedData = decodedData {
                if decodedData.images.isEmpty {
                    decodedData.images = scanFolderForImages(album: folder.absoluteString)
                    rebuildAlbumIndex(folder: folder)
                    return decodedData
                }
            }
            return decodedData
        }
        return nil
    }
}
