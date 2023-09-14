//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation
import UIKit

class PhotoPropertiesViewModel {
    
    // MARK: - Properties
    let images: [AlbumImage]
    let galleryManager: GalleryManager
    
    //MARK: - Init
    init(images: [AlbumImage], galleryManager: GalleryManager) {
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
            let attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName).relativePath) as NSDictionary
            if let _attr = attr {
                fileSize = _attr.fileSize();
            }
        } catch {
            
        }
        return fileSize
    }
    
    func getFileCreationDate() -> Date? {
        var date: Date?
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
        var albumImage: AlbumImage?
        albumImage = self.galleryManager.loadAlbumImage(id: photoID.fileName)
        return albumImage?.title ?? ""
    }
    
    func getImage() -> UIImage {
        UIImage(contentsOfFile: galleryManager.resolvePathFor(imageName: images.first!.fileName))!
    }
    
    func updateAlbumImage(albumImage: AlbumImage) {
        self.galleryManager.updateAlbumImage(image: albumImage)
    }
}
