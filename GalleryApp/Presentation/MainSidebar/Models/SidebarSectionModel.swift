//
//  SidebarSection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 11.03.2023.
//

import Foundation
import RxDataSources

/// Struct representing Sidebar Section
struct SidebarSectionModel {
    internal init(name: String, items: [SidebarItem]) {
        self.name = name
        self.items = items
    }
    
    var name: String
    var items: [SidebarItem]
    
    static var empty: Self {
        Self(name: "None", items: [SidebarItem]())
    }
}

extension SidebarSectionModel: AnimatableSectionModelType {
    init(original: SidebarSectionModel, items: [SidebarItem]) {
        self.name = original.name
        self.items = items
    }
    
    var identity: String {
        return name
    }
}

extension SidebarSectionModel: Equatable {
    
}
