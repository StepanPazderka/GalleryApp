//
//  FileScanner.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 11.06.2022.
//

import Foundation

class FileScannerManager {
    let settings: SettingsManager
    
    init(settings: SettingsManager) {
        self.settings = settings
    }
    
    func scanAlbumFolderForImages(albumName: String? = nil) -> [AlbumImage] {
        var outputImageList: [AlbumImage] = []
        
        do {
            let scannedFiles = try FileManager.default.contentsOfDirectory(at: settings.selectedGalleryPath.appendingPathComponent(albumName ?? ""), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                .filter {
                    let fileExtension = $0.pathExtension.lowercased()
                    if self.settings.allowedExtensions.contains(fileExtension) {
                        return true
                    }
                    return false
                }
            outputImageList = scannedFiles.map {
                let fileAttributes = try? FileManager.default.attributesOfItem(atPath: $0.path)
                
                return AlbumImage(fileName: $0.lastPathComponent,
                                  date: fileAttributes?[.creationDate] as? Date ?? Date(), title: nil)
            }
        } catch {
            print(error.localizedDescription)
        }
        return outputImageList
    }
}
