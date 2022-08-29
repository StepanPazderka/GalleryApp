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
    let image: UIImage?
    let identifier: UUID

    internal init(id: UUID, title: String?, image: UIImage?) {
        self.identifier = id
        self.title = title
        self.image = image
    }

    init?(from: AlbumIndex) {
        self.identifier = from.id
        self.title = from.name
        let thumbnailImage: UIImage? = nil
        self.image = thumbnailImage
    }
    
    static var empty: Self {
        Self(id: UUID(), title: "", image: nil)
    }
}
