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
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.updateLibraries()
    }
    
    func updateLibraries() {
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
        } catch {
            print("Error getting directory contents: \(error)")
        }
        
        let sorted = directories.sorted { library1, library2 in
            library1 < library2
        }
        
        self.libraries.onNext([AnimatableSectionModel(model: "Nothing", items: sorted)])
    }
    
    func loadGalleriesAsObservable() -> Observable<[SectionModel<Void, String>]> {
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
            print("Directories in Documents directory: \(directories)")
        } catch {
            print("Error getting directory contents: \(error)")
        }
                
        return Observable.just([SectionModel(model: (), items: directories)])
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
}
