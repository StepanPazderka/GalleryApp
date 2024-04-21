//
//  PathResolver.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.02.2023.
//

import Foundation

class PathResolver {
    
    // MARK: - Properties
    private let settingsManager: SettingsManagerImpl
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var selectedGalleryPath: URL {
        get {
            return libraryPath.appendingPathComponent(settingsManager.selectedGalleryName)
        }
    }
    
    // MARK: - Init
    init(settingsManager: SettingsManagerImpl) {
        self.settingsManager = settingsManager
    }
    
    /**
     Finds absolute path for image
     - parameter imageName: Image name in string with or without extension
     
     - returns: Complete image path URL with file name extension
     */
    
    func resolveThumbPathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
    }
    
    func resolvePathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
}
