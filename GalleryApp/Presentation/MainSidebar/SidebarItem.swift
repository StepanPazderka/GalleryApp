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
    private let identifier = UUID()

    internal init(title: String?, image: UIImage?) {
        self.title = title
        self.image = image
    }

    init?(from: AlbumIndex) {
        self.title = from.name
        let thumbnailImage: UIImage? = nil
        self.image = thumbnailImage
    }
}
