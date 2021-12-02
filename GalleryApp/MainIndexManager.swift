//
//  MainIndexManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation

class MainIndexManager {
    static func createAlbum(name: String) {
        try! FileManager.default.createDirectory(at: GalleryManager.documentDirectory.appendingPathComponent(name), withIntermediateDirectories: true, attributes: nil)
    }

    static func listAlbums() -> [AlbumIndex] {
        var listedAlbums = [AlbumIndex]()
        let loadDocumentDirectoryContent = try! FileManager.default.contentsOfDirectory(at: GalleryManager.documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//        listedAlbums = loadDocumentDirectoryContent.filter { $0.lastPathComponent == "index.json" }
        return listedAlbums
    }
}
