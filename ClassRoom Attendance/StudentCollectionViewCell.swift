//
//  StudentCollectionViewCell.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import UIKit

class StudentCollectionViewCell: UICollectionViewCell {
    @IBOutlet var studentImage: UIImageView!
    @IBOutlet var studentName: UILabel!
    @IBOutlet var studentRoll: UILabel!
    func setup(with student: Student) { //Setup each cell of collection view
        let imageData = student.image
        let maxWidth = Int(self.bounds.width)
        DispatchQueue(label: "com.imagedecode", qos: .userInteractive, attributes: .concurrent).async { [weak self] in
            guard let self = self else {
                return
            }
            if let imageData = imageData, let image = imageData.scaleImageData(toMaximumPixelCount: maxWidth) {
                DispatchQueue.main.async {
                    self.studentImage.image = image
                }
            }
        }
        studentName.text = student.name
        studentRoll.text = String(student.roll)
    }
}


//Downscales the image
extension Data {
    func scaleImageData(toMaximumPixelCount: Int) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        if let source = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) {
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 768
            ] as CFDictionary

            if let downsampleImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) {
                let downsampled = UIImage(cgImage: downsampleImage)
                return downsampled
            }
        }
        return nil
    }
    enum ImageDataError: Error {
        case invalidImageData
    }
    func throwingScale(toMaximumPixelCount: Int) throws -> UIImage {
        if let image = self.scaleImageData(toMaximumPixelCount: toMaximumPixelCount) {
            return image
        } else {
            throw ImageDataError.invalidImageData
        }
    }
}
