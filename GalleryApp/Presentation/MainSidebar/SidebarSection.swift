//
//  SidebarSection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 11.03.2023.
//

import Foundation
import RxDataSources

/// Struct representing Sidebar Section
struct SidebarSection {
    internal init(category: String, items: [SidebarCell]) {
        self.category = category
        self.items = items
    }
    
    var category: String
    var items: [SidebarCell]
}

extension SidebarSection: SectionModelType {
    init(original: SidebarSection, items: [SidebarCell]) {
        self.category = original.category
        self.items = items
    }
    
    var identity: String {
        return category
    }
}
