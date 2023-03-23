//
//  SidebarSection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 11.03.2023.
//

import Foundation
import RxDataSources

struct SidebarSection {
    internal init(category: String, items: [SidebarItem]) {
        self.category = category
        self.items = items
    }
    
    var category: String
    var items: [SidebarItem]
}

extension SidebarSection: SectionModelType {
    init(original: SidebarSection, items: [SidebarItem]) {
        self.category = original.category
        self.items = items
    }
    
    var identity: String {
        return category
    }
}
