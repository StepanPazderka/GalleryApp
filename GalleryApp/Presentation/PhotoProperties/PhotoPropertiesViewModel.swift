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
    init(photoIDs: [AlbumImage], galleryManager: GalleryManager) {
        self.images = photoIDs
        self.galleryManager = galleryManager
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            var attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName).relativePath) as NSDictionary
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
        UIImage(contentsOfFile: self.galleryManager.selectedGalleryPath.appendingPathComponent(images.first!.fileName).relativePath)!
    }
    
    func updateAlbumImage(albumImage: AlbumImage) {
        self.galleryManager.updateAlbumImage(image: albumImage)
    }
}
