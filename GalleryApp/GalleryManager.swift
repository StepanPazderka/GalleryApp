//
//  GalleryManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 18.01.2021.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import RxSwift

class GalleryManager {
//    let allowedTypes = [UTType.image]

    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func loadImage() -> UIImage {
        let outputImage: UIImage = UIImage()
        return outputImage
    }
    
    static func listImages() -> [String] {
        var outputImageList: [URL] = []

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            print("Document Directory: \(documentDirectory)")
            
            for file in files.filter({ file in
                let allowedTypes = [UTType.image]
                if let typeID = try? file.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
                {
                    for allowedType in allowedTypes {
                        if UTType(typeID)!.supertypes.contains(allowedType) {
                            return true
                        }
                    }
                }
                return false
            })
            {
                outputImageList.append(file)
            }
        } catch {
            print(error.localizedDescription)
        }

        return outputImageList.filter { $0.hasDirectoryPath == false }.map { $0.absoluteURL.lastPathComponent }
    }
    
    static func buildThumbs() {
        let images = listImages()
        for image in images {
            let newFilename = image
            let newImage = ImageResizer.resizeImage(image: UIImage(contentsOfFile: documentDirectory.appendingPathComponent(image).relativePath)!, targetSize: CGSize(width: 200, height: 200))
            if let jpegImage = newImage?.jpegData(compressionQuality: 1.0) {
                if FileManager.default.fileExists(atPath: documentDirectory.appendingPathComponent("thumbs").path) == false {
                    try? FileManager.default.createDirectory(atPath: documentDirectory.appendingPathComponent("thumbs").path, withIntermediateDirectories: false)
                }
                var filePath = documentDirectory.appendingPathComponent("thumbs").appendingPathComponent(newFilename)
                filePath = filePath.deletingPathExtension()
                filePath = filePath.appendingPathExtension("jpg")
                try? jpegImage.write(to: filePath)
            }
        }
    }
    
    static func writeThumb(image: UIImage) {
        
    }
    
    static func rebuildIndex(folder: URL) {
        let jsonTest = AlbumIndex(name: folder.lastPathComponent, images: self.listImages(), thumbnail: self.listImages().first!)
        buildThumbs()
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func updateIndex(folder: URL, index: AlbumIndex) {
        let jsonTest = index
        
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func loadIndex(folder: URL) -> AlbumIndex {
        if !FileManager.default.fileExists(atPath: folder.appendingPathComponent("index.json").relativePath) {
            rebuildIndex(folder: folder)
        }
        let jsonDATA = try! String(contentsOfFile: folder.appendingPathComponent("index.json").relativePath).data(using: .unicode)
        print("JSON Data: \(String(describing: jsonDATA))")
        print(GalleryManager.documentDirectory)
        let decodedData = try! JSONDecoder().decode(AlbumIndex.self, from: jsonDATA!)
        return decodedData
    }

    static func loadIndexRX(folder: URL) -> Observable<AlbumIndex> {
        .create { observer in
            return Disposables.create()
        }
    }
}
