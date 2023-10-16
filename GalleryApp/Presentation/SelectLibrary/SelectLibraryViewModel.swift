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
    
    var libraries = BehaviorSubject(value: [AnimatableSectionModel(model: "Nothing", items: [String]())])
    
    var userDefaults: UserDefaults = UserDefaults.standard
    let settingsManager: SettingsManager
    let galleryManager: GalleryManager
    
    init(settingsManager: SettingsManager, galleryManagery: GalleryManager) {
        self.settingsManager = settingsManager
        self.galleryManager = galleryManagery
        self.updateLibraries()
    }
    
    /// Scans app directory for subdirectories and updates libraries
    func updateLibraries() {
        var foundDirectoriesInDocumentsFolder: [String] = [String]()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            foundDirectoriesInDocumentsFolder = directoryContents.filter { (path: String) -> Bool in
                var isDirectory: ObjCBool = false
                let fullPath = documentsDirectory.appendingPathComponent(path).path
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                return isDirectory.boolValue
            }
        } catch {
            print("Error getting directory contents: \(error)")
        }
        
        let librariesSortedByName = foundDirectoriesInDocumentsFolder.sorted { libraryLHS, libraryRHS in
            libraryLHS < libraryRHS
        }
        
        self.libraries.onNext([AnimatableSectionModel(model: "Nothing", items: librariesSortedByName)])
    }
    
    func SectionModelsGalleriesAsObservable() -> Observable<[AnimatableSectionModel<String, String>]> {
        return Observable<Int>.interval(.milliseconds(1500), scheduler: MainScheduler.instance)
            .flatMap { _ in self.listGalleryDirectoriesAsObservable() }
            .distinctUntilChanged()
            .map { [AnimatableSectionModel(model: "nothing", items: $0)] }
    }
    
    
    func listGalleryDirectoriesAsObservable() -> Observable<[String]> {
        return Observable.create { observer in
            var directories: [String] = [String]()
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                let directoryContents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
                directories = directoryContents.filter { (path: String) -> Bool in
                    var isDirectory: ObjCBool = false
                    let fullPath = documentsDirectory.appendingPathComponent(path).path
                    FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                    return isDirectory.boolValue
                }
                NSLog("Directories in Documents directory: \(directories) Date: \(Date())")
                observer.onNext(directories)
            } catch {
                print("Error getting directory contents: \(error)")
            }
            
            return Disposables.create()
        }
    }
    
    func createNewLibrary(withName: String, callback: (() -> (Void))? = nil) throws {
        do {
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
        settingsManager.set(key: .selectedGallery, value: library)
    }
    
    func delete(gallery: String) {
        self.galleryManager.delete(gallery: gallery)
    }
}
