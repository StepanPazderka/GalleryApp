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
    var selectedGalleryPath: URL
    
    init(config: Config) {
        self.config = config
        self.selectedGalleryPath = config.libraryPath.appendingPathComponent(config.selectedGallery)
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

//        return outputImageList.filter { $0.hasDirectoryPath == false }.map { $0.absoluteURL.lastPathComponent }
//        return outputImageList.map { AlbumImage(fileName: $0.fileName, date: $0.date) }
        if outputImageList.isEmpty {
            rebuildGallery()
        }
        return outputImageList
    }
    
    func listAllImages() -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []
        let indexes = listAlbums(url: nil)

        
//        for index in indexes {
//            let images = index.images
//            outputImageList.append(contentsOf: images.map { image in
//                var newFilename = URL(fileURLWithPath: index.name).appendingPathComponent(image.fileName).relativeString
//                var newDate = image.date
//
//                return AlbumImage(fileName: newFilename, date: newDate)
//            })
//        }
        
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
    
    func rebuildGallery() {
        
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
