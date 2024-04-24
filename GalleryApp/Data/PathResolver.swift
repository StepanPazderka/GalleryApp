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
    private var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	private var currentlySelectedGalleryID: UUID!
    var selectedGalleryPath: URL {
        get {
			return libraryPath.appendingPathComponent(currentlySelectedGalleryID.uuidString)
        }
    }
    let disposeBag = DisposeBag()
	
    // MARK: - Init
	init(settingsManager: SettingsManagerImpl) {
        self.settingsManager = settingsManager
		self.settingsManager.getCurrentlySelectedGalleryIDAsObservable().catch { [weak self] error -> Observable<String> in
			return self?.settingsManager.getCurrentlySelectedGalleryIDAsObservable() ?? .empty()
		}.subscribe(onNext: { [weak self] galleryID in
			self?.currentlySelectedGalleryID = UUID(uuidString: galleryID)!
		}).disposed(by: disposeBag)
    }
    
    /**
     Finds absolute path for image
     - parameter imageName: Image name in string with or without extension
     
     - returns: Complete image path URL with file name extension
     */
	
	internal func resolveDocumentsPath() -> URL {
		return self.libraryPath
	}
    
    internal func resolveThumbPathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
    }
    
    internal func resolvePathFor(imageName: String) -> String {
        return self.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
    }
}
