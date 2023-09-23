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
    internal init(category: String, items: [SidebarItem]) {
        self.name = category
        self.items = items
    }
    
    var name: String
    var items: [SidebarItem]
    
    static var empty: Self {
        Self(category: "None", items: [SidebarItem]())
    }
}

extension SidebarSection: SectionModelType {
    init(original: SidebarSection, items: [SidebarItem]) {
        self.name = original.name
        self.items = items
    }
    
    var identity: String {
        return name
    }
}
