//
//  SidebarItem.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.01.2022.
//

import Foundation
import UIKit

struct SidebarItem: Hashable {
    let title: String?
    private let originalImage: UIImage?
    var image: UIImage? {
        get {
            switch self.type {
            case .allPhotos:
                return UIImage(systemName: "photo.on.rectangle.angled")?.withTintColor(.tintColor)
            case .album:
                return originalImage
            }
        }
    }
    let identifier: UUID?
    let type: buttonType
    
    enum buttonType {
        case album
        case allPhotos
    }

    internal init(id: UUID? = UUID(), title: String?, image: UIImage? = nil, buttonType: buttonType) {
        self.identifier = id
        self.title = title
        self.originalImage = image
        self.type = buttonType
    }

    init?(from album: AlbumIndex) {
        self.identifier = album.id
        self.title = album.name
        let thumbnailImage: UIImage? = nil
        self.originalImage = thumbnailImage
        self.type = .album
    }
    
    static var empty: Self {
        Self(id: UUID(), title: "", image: nil, buttonType: .album)
    }
}
