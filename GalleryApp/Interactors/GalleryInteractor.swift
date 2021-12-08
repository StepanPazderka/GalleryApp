//
//  MainIndexManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation

class GalleryInteractor {
    static func createAlbum(name: String) throws {
        try! FileManager.default.createDirectory(at: IndexInteractor.documentDirectory.appendingPathComponent(name), withIntermediateDirectories: true, attributes: nil)
    }

    static func listAlbums() -> [AlbumIndex] {
        var listedAlbums = [AlbumIndex]()
        let loadDocumentDirectoryContent = try! FileManager.default.contentsOfDirectory(at: IndexInteractor.documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            .filter { $0.lastPathComponent == "index.json" }
            .map { AlbumIndex(from: $0) }
            .map { listedAlbums.append($0!) }
        return listedAlbums
    }
}
