//
//  IFImageCell.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/23/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFImageCell: UICollectionViewCell {
    
	@IBOutlet weak var imageThumbnailView: UIImageView!
	var downloadTask: NSURLSessionDownloadTask?

	func loadImage(imageURL: NSURL) {
		layer.shouldRasterize = true
		layer.rasterizationScale = UIScreen.mainScreen().scale;
		// First look for the image in memory cache
		if let imageInMemory = IFImageCache.sharedCache.imageFromMemoryCacheForURL(imageURL) {
			imageThumbnailView.image = imageInMemory
		}
		else {
			// placeholder until image is fetched
			imageThumbnailView.image = UIImage(named: "Placeholder")

			// keep track of the tag to make sure cell hasn't been reused before download od image completes
			let cellTag = self.tag

			// look for the image in the disk cache
			IFImageCache.sharedCache.fetchDiskImageForURL(imageURL, completion: { (image) -> Void in
				if let imageIndisk = image {
					if self.tag == cellTag {
						self.imageThumbnailView.image = imageIndisk
					}
				}
				else {
					self.downloadTask?.cancel()

					// download image from server
					self.downloadTask = IFImageDownloader.sharedInstance.downloadImageWithURL(imageURL, completion: { (image, error) -> Void in
						if let downloadedImage = image {
							if self.tag == cellTag {
								self.imageThumbnailView.image = downloadedImage
							}
						}
					})
				}
			})
		}

	}


}
