//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation

struct AlbumIndex: Codable {
    var id: UUID = UUID()
    var name: String
    var images: [AlbumImage]
    var thumbnail: String?
    var thumbnailsSize: Float = 200
    var showingAnnotations: Bool? = false

    internal init(id: UUID = UUID() ,name: String, images: [AlbumImage], thumbnail: String, showingAnnotations: Bool? = false) {
        self.id = id
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
        self.thumbnailsSize = 200
        self.showingAnnotations = showingAnnotations
    }

    init?(from entity: URL) {
        let albumIndexPath = entity.lastPathComponent == kAlbumIndex ? entity.relativePath : entity.appendingPathComponent(kAlbumIndex).relativePath

        guard let jsonData = try? String(contentsOfFile: albumIndexPath).data(using: .unicode) else {
            return nil
        }
    
        guard let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData) else {
            return nil
        }

        self.name = decodedData.name
        self.images = decodedData.images
        self.thumbnail = decodedData.thumbnail
        self.id = decodedData.id
        self.thumbnailsSize = decodedData.thumbnailsSize
        self.showingAnnotations = decodedData.showingAnnotations
    }
    
    static var empty: Self {
        Self(name: "", images: [], thumbnail: "", showingAnnotations: false)
    }
}
