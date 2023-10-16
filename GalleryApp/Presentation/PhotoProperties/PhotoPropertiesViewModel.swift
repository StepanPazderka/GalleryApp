//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation

class PhotoPropertiesViewModel {
    
    // MARK: - Properties
    let images: [GalleryImage]
    let galleryManager: GalleryManager
    
    //MARK: - Init
    init(images: [GalleryImage], galleryManager: GalleryManager) {
        self.images = images
        self.galleryManager = galleryManager
    }
    
    func getFileType() -> String? {
        let fileURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName)
        
        return fileURL.pathExtension.uppercased()
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            for image in images {
                let attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(image.fileName).relativePath) as NSDictionary
                if let attr {
                    fileSize += attr.fileSize();
                }
            }
        } catch {
            
        }
        return fileSize
    }
    
    func getFileCreationDate() -> Date? {
        var date: Date?
        
        guard images.count == 1 else { return nil }
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName).relativePath)
            date = attr[FileAttributeKey.creationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getFileModifiedDate() -> Date? {
        var date: Date?
        
        guard images.count == 1 else { return nil }
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName).relativePath)
            date = attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getPhotoTitle() -> String {
        guard let photoID = images.first else { return "" }
        var albumImage: GalleryImage?
        albumImage = self.galleryManager.loadAlbumImage(id: photoID.fileName)
        return albumImage?.title ?? ""
    }
    
    func resolveImagePaths() -> [String] {
        images.map { self.galleryManager.resolvePathFor(imageName: $0.fileName) }
    }
    
    func updateAlbumImage(albumImage: GalleryImage) {
        self.galleryManager.updateAlbumImage(image: albumImage)
    }
}
