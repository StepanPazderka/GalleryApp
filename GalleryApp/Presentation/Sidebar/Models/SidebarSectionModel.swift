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
	var name: String
	var items: [SidebarItemModel]
	let type: SidebarSectionCategory
	
	init(type: SidebarSectionCategory, name: String, items: [SidebarItemModel]) {
		self.type = type
        self.name = name
        self.items = items
    }
    
    static var empty: Self {
		Self(type: .unknown, name: "None", items: [SidebarItemModel]())
    }
}

extension SidebarSectionModel: AnimatableSectionModelType {
    init(original: SidebarSectionModel, items: [SidebarItemModel]) {
        self.name = original.name
        self.items = items
		self.type = .unknown
    }
    
    var identity: String {
        return name
    }
}

extension SidebarSectionModel: Equatable {
    
}
