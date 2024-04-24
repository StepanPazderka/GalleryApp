//
//  SidebarItem.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.01.2022.
//

import Foundation
import RxDataSources

struct SidebarItem: Hashable {
    let title: String?
	let identifier: UUID?
	let type: buttonType

    private var customImage: UIImage?
    var image: UIImage? {
        get {
            switch self.type {
            case .allPhotos:
                return UIImage(systemName: "photo.on.rectangle.angled")?.withTintColor(.tintColor)
            case .album:
                if let customImage {
                    return customImage
                } else {
                    return UIImage(systemName: "square")?.withTintColor(.tintColor)
                }
            }
        }
		set {
			customImage = newValue
		}
    }
    
    enum buttonType {
        case album
        case allPhotos
    }

    internal init(id: UUID? = UUID(), title: String?, image: UIImage? = nil, buttonType: buttonType) {
        self.identifier = id
        self.title = title
        self.customImage = image
        self.type = buttonType
    }

    init?(from album: AlbumIndex) {
        self.identifier = album.id
        self.title = album.name
        let thumbnailImage: UIImage? = nil
        self.customImage = thumbnailImage
        self.type = .album
    }
    
    static var empty: Self {
        Self(id: UUID(), title: "", image: nil, buttonType: .album)
    }
}

extension SidebarItem: IdentifiableType {
	var identity: String {
		self.identifier?.uuidString ?? "Nothing"
	}
}
