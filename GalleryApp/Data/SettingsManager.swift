//
//  SettingsManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.05.2022.
//

import Foundation
import UniformTypeIdentifiers
import RxSwift

class SettingsManager {
    
    let unsecureStorage: UnsecureStorage
    var selectedGallery: String
    var selectedGalleryAsObservable = BehaviorSubject(value: "Default Library")
    var selectedGalleryPath: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(selectedGallery)
    }
    let allowedTypes = [UTType.jpeg, UTType.tiff, UTType.png]
    var allowedExtensions: [String] {
        allowedTypes.compactMap { $0.tags[.filenameExtension]}.flatMap { $0 }
    }
    let disposeBag = DisposeBag()

    init(unsecureStorage: UnsecureStorage) {
        self.unsecureStorage = unsecureStorage
        
        if let loadedSelectedGallery: String = unsecureStorage.load(key: .selectedGallery) {
            selectedGallery = loadedSelectedGallery
            selectedGalleryAsObservable.onNext(loadedSelectedGallery)
        } else {
            unsecureStorage.save(key: .selectedGallery, value: "Default Gallery")
            selectedGallery = "Default Gallery"
            selectedGalleryAsObservable.onNext("Default Gallery")
        }
        
        self.selectedGalleryAsObservable.subscribe(onNext: { value in
            self.selectedGallery = value
        }).disposed(by: disposeBag)
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
        selectedGalleryAsObservable.onNext(value)
    }
}
