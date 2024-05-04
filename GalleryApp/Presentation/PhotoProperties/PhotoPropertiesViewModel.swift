//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation
import RxSwift
import RxCocoa

class PhotoPropertiesViewModel {
    
    // MARK: - Properties
    let selectedImages: [GalleryImage]
    let galleryManager: GalleryManager
    let pathResolver: PathResolver
    
    //MARK: - Init
    init(images: [GalleryImage], galleryManager: GalleryManager, pathResolver: PathResolver) {
        self.selectedImages = images
        self.galleryManager = galleryManager
        self.pathResolver = pathResolver
    }
    
    func getFileType() -> String? {
        let fileURL = self.pathResolver.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName)
        
        return fileURL.pathExtension.uppercased()
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            for image in selectedImages {
                let fileAttributes: NSDictionary? = try FileManager.default.attributesOfItem(atPath: self.pathResolver.selectedGalleryPath.appendingPathComponent(image.fileName).relativePath) as NSDictionary
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
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.pathResolver.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName).relativePath)
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
            let attr = try FileManager.default.attributesOfItem(atPath: self.pathResolver.selectedGalleryPath.appendingPathComponent(selectedImages.first!.fileName).relativePath)
            date = attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
        return date
    }

    func getPhotoTitleAsObservable() -> Observable<String> {
		if selectedImages.count == 1, let selectedImage = selectedImages.first {
			return galleryManager.loadImageAsObservable(with: selectedImage.id).map { $0.title ?? "" }
		} else {
			return .empty()
		}
    }
    
    func resolveImagePaths() -> [String] {
        selectedImages.map { self.pathResolver.resolvePathFor(imageName: $0.fileName) }
    }
    
    func update(image: GalleryImage) {
        self.galleryManager.update(image: image)
    }
}
