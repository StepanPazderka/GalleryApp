//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation

class PhotoPropertiesViewModel {
    
    // MARK: - Properties
    let imagePaths: [URL]
    let galleryManager: GalleryManager
    
    //MARK: - Init
    init(photoIDs: [URL], galleryManager: GalleryManager) {
        self.imagePaths = photoIDs
        self.galleryManager = galleryManager
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            var attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: imagePaths.first!.relativePath) as NSDictionary
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
            let attr = try FileManager.default.attributesOfItem(atPath: imagePaths.first!.relativePath)
            date = attr[FileAttributeKey.creationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getFileModifiedDate() -> Date? {
        var date: Date?
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: imagePaths.first!.lastPathComponent)
            date = attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getPhotoTitle() -> String {
        guard let photoID = imagePaths.first else { return "" }
        var albumImage: AlbumImage?
        albumImage = self.galleryManager.loadAlbumImage(id: photoID.lastPathComponent)
        return albumImage?.title ?? ""
    }
    
    func updateAlbumImage(albumImage: AlbumImage) {
        self.galleryManager.updateAlbumImage(image: albumImage)
    }
}
