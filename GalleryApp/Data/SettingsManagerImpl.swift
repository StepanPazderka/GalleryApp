//
//  SettingsManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.05.2022.
//

import Foundation
import UniformTypeIdentifiers
import RxSwift

final class SettingsManagerImpl: SettingsManager {
	internal let unsecureStorage: UnsecureStorage
	var selectedGalleryName: String!
    let allowedTypes = [UTType.jpeg, UTType.tiff, UTType.png]
    var allowedExtensions: [String] {
        allowedTypes.compactMap { $0.tags[.filenameExtension] }.flatMap { $0 }
    }
    let disposeBag = DisposeBag()

    init(unsecureStorage: UnsecureStorage) {
        self.unsecureStorage = unsecureStorage
		
		guard let selectedGalleryID = load(key: .selectedGallery) else { set(key: .selectedGallery, value: "00"); return }
    }
    
    func getSelectedLibraryName() -> String {
        if let loadedSelectedGallery: String = unsecureStorage.load(key: .selectedGallery) {
            return loadedSelectedGallery
        } else {
            unsecureStorage.save(key: .selectedGallery, value: "Default Gallery")
            return "Default Gallery"
        }
    }
	
	func load(key: SettingsKey) -> String? {
		unsecureStorage.load(key: .selectedGallery, type: String.self)
	}
    
    func set(key: SettingsKey, value: String) {
		selectedGalleryName = value
        unsecureStorage.save(key: key, value: value)
    }
	
	func setSelectedGallery(id: String) {
		unsecureStorage.save(key: .selectedGallery, value: id)
	}
	
	func get(key: SettingsKey) -> Observable<String> {
		UserDefaults.standard.rx.observe(String.self, key.rawValue).compactMap { $0 }
	}
	
	func getCurrentlySelectedGalleryIDAsObservable() -> Observable<String> {
		unsecureStorage.getAsObservable(key: .selectedGallery)
	}
}
