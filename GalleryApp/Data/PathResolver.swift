//
//  PathResolver.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.02.2023.
//

import Foundation
import RxSwift

class PathResolver {
    
    // MARK: - Properties
    private let settingsManager: SettingsManagerImpl
    private var appDocumentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	private var currentlySelectedGalleryID: String? {
		settingsManager.unsecureStorage.load(key: .selectedGallery)
	}
    var selectedGalleryPath: URL {
		get {
			if let currentlySelectedGalleryID {
				return appDocumentsDirectory.appendingPathComponent(currentlySelectedGalleryID)
			} else {
				return appDocumentsDirectory
			}
		}
    }
    private let disposeBag = DisposeBag()
	
    // MARK: - Init
	init(settingsManager: SettingsManagerImpl) {
        self.settingsManager = settingsManager
    }
    
    /**
     Finds absolute path for image
     - parameter imageName: Image name in string with or without extension
     
     - returns: Complete image path URL with file name extension
     */
	
	internal func resolveDocumentsPath() -> URL {
		return self.appDocumentsDirectory
	}
    
    internal func resolveThumbPathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
    }
    
    internal func resolvePathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
}
