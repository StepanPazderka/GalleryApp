//
//  FileObserver.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.10.2023.
//

import Foundation

class FileObserver {
    
    let fileDescriptor: Int32
    let source: DispatchSourceFileSystemObject
    
    init(filePath: String) {
        fileDescriptor = open(filePath, O_EVTONLY)
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: DispatchQueue.global())
        
        source.setEventHandler {
            print("File changed!")
        }
        
        source.resume()
    }
    
    deinit {
        close(fileDescriptor)
    }
    
}
