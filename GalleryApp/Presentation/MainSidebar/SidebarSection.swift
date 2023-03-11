//
//  SidebarSection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 26.01.2022.
//

import Foundation
import RxDataSources

enum SidebarSection: String, CaseIterable {
    case mainButtons
    case albumsButtons = "Albums"
    case smartAlbumsButtons = "Smart Albums"
}

