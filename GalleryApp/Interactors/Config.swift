//
//  Config.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.12.2021.
//

import Foundation

class Config {
    internal init() {
        
    }
    
    let defaults = UserDefaults.standard
    var libraryPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var selectedGallery: String {
        get {
            if let selectedGallery = defaults.object(forKey: "selectedGallery") as? String {
                return selectedGallery
            } else {
                return "Default Gallery"
            }
        }
        
    }
}
