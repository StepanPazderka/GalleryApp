//
//  PhotoPropertiesViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation

class PhotoPropertiesViewModel {
    
    let photoIDs: [String]
    
    init(photoIDs: [String]) {
        self.photoIDs = photoIDs
    }
    
    func getFileSize() -> UInt64 {
        var fileSize: UInt64 = 0
        
        do {
            var attr: NSDictionary? = try FileManager.default.attributesOfItem(atPath: photoIDs.first!) as NSDictionary
            if let _attr = attr {
                fileSize = _attr.fileSize();
            }
        } catch {
            
        }
        return fileSize
    }
}
