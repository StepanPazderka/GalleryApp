//
//  GalleryManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 18.01.2021.
//

import Foundation
import UIKit

class GalleryManager {
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func loadImage() -> UIImage {
        var outputImage: UIImage = UIImage()
        return outputImage
    }
    
    static func listImages() -> [URL] {
        var outputImageList: [URL] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            for file in files {
                outputImageList.append(file)
            }
        } catch {
            print(error.localizedDescription)
        }

        return outputImageList
    }
}
