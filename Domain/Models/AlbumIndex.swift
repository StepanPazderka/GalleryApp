//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation

struct AlbumIndex: Codable {
    var name: String
    var images: [AlbumImage]
    var thumbnail: String

    internal init(name: String, images: [AlbumImage], thumbnail: String) {
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
    }

    init?(from entity: URL) {
        let indexPath = entity.lastPathComponent == "index.json" ? entity.relativePath : entity.appendingPathComponent("index.json").relativePath
        
        let jsonDATA = try? String(contentsOfFile: indexPath).data(using: .unicode)
        if let jsonData = jsonDATA {
            let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData)
            if let album = decodedData {
                self.name = album.name
                self.images = album.images
                self.thumbnail = album.thumbnail
                return 
            }
        }
        
        return nil
    }
    
    static var empty: Self {
        Self(name: "", images: [], thumbnail: "")
    }
}
