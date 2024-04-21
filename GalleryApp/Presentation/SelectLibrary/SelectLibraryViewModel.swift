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
	var userDefaults: UserDefaults = UserDefaults.standard
	let settingsManager: SettingsManagerImpl
	private let galleryManager: GalleryManager
	
	init(settingsManager: SettingsManagerImpl, galleryManagery: GalleryManager) {
		self.settingsManager = settingsManager
		self.galleryManager = galleryManagery
	}

	func loadAnimatedSectionsForCollectionView() -> Observable<[SelectLibraryAnimatableSectionModel]> {
		self.galleryManager.loadGalleries()
			.map { [SelectLibraryAnimatableSectionModel(name: "Galleries", items: $0)] }
	}
	
	func loadCurrentGalleryAsObservable() -> Observable<GalleryIndex> {
		self.galleryManager.loadCurrentGalleryIndexAsObservable()
	}
    
    func createNewLibrary(withName: String, callback: (() -> (Void))? = nil) throws {
        do {
			try galleryManager.createGalleryIndex(name: withName)
            try FileManager.default.createDirectory(at: FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(component: withName), withIntermediateDirectories: false)
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

    func switchTo(library: String) {		
		settingsManager.selectedGalleryName = library
        settingsManager.set(key: .selectedGallery, value: library)
    }
    
    func delete(gallery: String) {
        self.galleryManager.deleteGallery(named: gallery)
    }
}
