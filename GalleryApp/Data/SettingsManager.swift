//
//  SettingsManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.05.2022.
//

import Foundation
import UniformTypeIdentifiers

class SettingsManager {
    
    let unsecureStorage: UnsecureStorage
    var selectedGallery: String
    var selectedGalleryPath: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(selectedGallery)
    }
    let allowedTypes = [UTType.jpeg, UTType.tiff, UTType.png]
    var allowedExtensions: [String] {
        allowedTypes.compactMap { $0.tags[.filenameExtension]}.flatMap { $0 }
    }

    init(unsecureStorage: UnsecureStorage) {
        self.unsecureStorage = unsecureStorage
        
        if let loadedSelectedGallery: String = unsecureStorage.load(key: .selectedGallery) {
            selectedGallery = loadedSelectedGallery
        } else {
            unsecureStorage.save(key: .selectedGallery, value: "Default Gallery")
            selectedGallery = "Default Gallery"
        }
    }
    
}
