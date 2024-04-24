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
	let unsecureStorage: UnsecureStorage
	var selectedGalleryName: String!
    var selectedGalleryPath: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(selectedGalleryName)
    }
    let allowedTypes = [UTType.jpeg, UTType.tiff, UTType.png]
    var allowedExtensions: [String] {
        allowedTypes.compactMap { $0.tags[.filenameExtension] }.flatMap { $0 }
    }
    let disposeBag = DisposeBag()

    init(unsecureStorage: UnsecureStorage) {
        self.unsecureStorage = unsecureStorage
        
    }
    
    func getSelectedLibraryName() -> String {
        if let loadedSelectedGallery: String = unsecureStorage.load(key: .selectedGallery) {
            return loadedSelectedGallery
        } else {
            unsecureStorage.save(key: .selectedGallery, value: "Default Gallery")
            return "Default Gallery"
        }
    }
    
    func set(key: SettingsKey, value: String) {
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
