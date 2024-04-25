//
//  SelectLibraryViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import RxSwift
import RxDataSources

class SelectLibraryViewModel {
	private var userDefaults: UserDefaults = UserDefaults.standard
	private let settingsManager: SettingsManager
	private let galleryManager: GalleryManager
	
	init(settingsManager: SettingsManagerImpl, galleryManagery: GalleryManager) {
		self.settingsManager = settingsManager
		self.galleryManager = galleryManagery
	}

	func loadAnimatedSectionsForCollectionView() -> Observable<[SelectLibraryAnimatableSectionModel]> {
		self.galleryManager.loadGalleriesAsObservable()
			.map { [SelectLibraryAnimatableSectionModel(name: "Galleries", items: $0)] }
	}
	
	func loadCurrentGalleryAsObservable() -> Observable<GalleryIndex> {
		self.galleryManager.loadCurrentGalleryIndexAsObservable()
	}
    
    func createNewLibrary(withName: String, callback: (() -> (Void))? = nil) throws {
        do {
			try galleryManager.createGalleryIndex(name: withName)
        } catch {
            throw error
        }
        
        if let callback {
            callback()
        }
    }
    
    func getSelectedLibraryString() -> String {
        if let selectedGallery = userDefaults.string(forKey: kSelectedGallery) {
            return selectedGallery
        } else { return "" }
    }

    func switchTo(library: UUID) {
		settingsManager.set(key: .selectedGallery, value: library.uuidString)
    }
    
    func delete(gallery: String) {
        self.galleryManager.deleteGallery(named: gallery)
    }
	
	func rename(gallery: GalleryIndex, withName: String) {
		var updatedGalleryIndex = gallery
		updatedGalleryIndex.mainGalleryName = withName
		self.galleryManager.updateGalleryIndex(newGalleryIndex: updatedGalleryIndex)
	}
}
