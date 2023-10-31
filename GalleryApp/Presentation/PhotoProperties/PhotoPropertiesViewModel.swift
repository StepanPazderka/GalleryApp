//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation

class PhotoPropertiesViewModel {
    
    // MARK: - Properties
    let selectedImages: [GalleryImage]
    let galleryManager: GalleryManager
    
    //MARK: - Init
    init(images: [GalleryImage], galleryManager: GalleryManager) {
        self.selectedImages = images
        self.galleryManager = galleryManager
    }
    
    func getFileType() -> String? {
        let fileURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName)
        
        return fileURL.pathExtension.uppercased()
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            for image in selectedImages {
                let fileAttributes: NSDictionary? = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(image.fileName).relativePath) as NSDictionary
                if let fileAttributes {
                    fileSize += fileAttributes.fileSize();
                }
            }
        } catch {
            
        }
        return fileSize
    }
    
    func getFileCreationDate() -> Date? {
        var date: Date?
        
        guard selectedImages.count == 1 else { return nil }
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName).relativePath)
            date = fileAttributes[FileAttributeKey.creationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getFileModifiedDate() -> Date? {
        var date: Date?
        
        guard selectedImages.count == 1 else { return nil }
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: self.galleryManager.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName).relativePath)
            date = attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
        return date
    }
    
    func getPhotoTitle() -> String {
        guard let photoID = selectedImages.first else { return "" }
        var albumImage: GalleryImage?
        albumImage = self.galleryManager.loadAlbumImage(id: photoID.fileName)
        return albumImage?.title ?? ""
    }
    
    func resolveImagePaths() -> [String] {
        selectedImages.map { self.galleryManager.resolvePathFor(imageName: $0.fileName) }
    }
    
    func update(image: GalleryImage) {
        self.galleryManager.update(image: image)
    }
}
