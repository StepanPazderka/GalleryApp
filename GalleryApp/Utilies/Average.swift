//
//  Average.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 15.06.2022.
//

import Foundation

func calculateAverage(_ numbers: [Float]) -> Float {
    var sum: Float = 0
    for number in numbers {
        sum += number
    }
    let average = sum / Float(numbers.count)
    return average
}
