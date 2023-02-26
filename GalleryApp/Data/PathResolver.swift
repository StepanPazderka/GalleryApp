//
//  PathResolver.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.02.2023.
//

import Foundation

class PathResolver {
    public static let shared = PathResolver()
    /**
     Finds absolute path for image
     - parameter imageName: Image name in string with or without extension
     
     - returns: Complete image path URL with extensions
     */
    func getPathFor(imageName: String) {
        let imageNameInURL: URL = URL(filePath: imageName)
        
        if imageNameInURL.pathExtension != nil {
            
        }
    }
}
