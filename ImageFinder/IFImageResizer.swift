//
//  UIImage+Resize.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/25/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import Foundation
import ImageIO

class IFImageResizer: NSObject {

	// Resize to thumbnail size for display and storage
	// Based on the explanation here: http://nshipster.com/image-resizing/
	class func resizeImageToThumbnail(image: UIImage, thumbnailWidth: CGFloat) -> UIImage {
		var imageInProcess = image
		let thumbnailHeight = (image.size.height / image.size.height) * thumbnailWidth
		let options: [NSString: NSObject] = [
			kCGImageSourceThumbnailMaxPixelSize: max(thumbnailWidth, thumbnailHeight),
			kCGImageSourceCreateThumbnailFromImageAlways: true
		]
		if let imageData = UIImageJPEGRepresentation(image, 1.0) {
			if let imageSource = CGImageSourceCreateWithData(imageData, nil) {
				let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options).flatMap { UIImage(CGImage: $0) }
				if let theImage = scaledImage {
					imageInProcess = theImage
				}
			}
		}
		return imageInProcess
	}
}

