//
//  IFImageCache.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/24/16.
//  Copyright © 2016 Luitel. All rights reserved.
//


/*
	Caches image to memory as well as stores them to disk for later use
*/

import UIKit

class IFImageCache: NSObject {

	var cache = NSCache()
	var imageURLDictionary = [String : [String]]()

	static let sharedCache = IFImageCache()

	// init
	private override init() {
		super.init()
		cache = NSCache()
		let cacheName = "com.luitel.IFImageCache"
		cache.name = cacheName
		if let theDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey("searchURLs") as? [String : [String]] {
			imageURLDictionary = theDictionary
		}

		// empty memory cache after receiving a memory warning
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("emptyMemoryCache"), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
	}

	// MARK: - Primary methods

	// Store
	func cacheImage(image: UIImage, imageURL: NSURL, searchTerm: String) {
		cacheImageToMemory(image, imageURL: imageURL)
		cacheImageToDisk(image, imageURL: imageURL, searchTerm: searchTerm)
	}

	// retrive from disk
	func fetchDiskImageForURL(imageURL: NSURL, completion: (image: UIImage?) -> Void) {
		let priority = DISPATCH_QUEUE_PRIORITY_HIGH
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			let diskImage = self.imageFromDiskCacheForURL(imageURL)
			dispatch_async(dispatch_get_main_queue()) {
				if let theImage = diskImage {
					self.cacheImageToMemory(theImage, imageURL: imageURL)
				}
				completion(image: diskImage)
			}
		}
	}

	// retrive from memory
	func imageFromMemoryCacheForURL(imageURL: NSURL) -> UIImage? {
		let key = keyForImageURL(imageURL)
		if let imageInMemory = imageForKey(key) {
			return imageInMemory
		}
		return nil
	}

	// MARK: - Store Image

	private func cacheImageToMemory(image: UIImage, imageURL: NSURL) {
		if !isImageCachedToMemory(imageURL) {
			cache.setObject(image, forKey: keyForImageURL(imageURL))
		}
	}

	private func cacheImageToDisk(image: UIImage, imageURL: NSURL, searchTerm: String) {
		if !isImageCachedToDisk(imageURL) {
			let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
			dispatch_async(dispatch_get_global_queue(priority, 0)) {
				if let imagePath = self.diskPathForImageURL(imageURL) {

					// update imageURL dictionary
					if var imagePaths = self.imageURLDictionary[searchTerm] {
						imagePaths.append(imagePath)
						self.imageURLDictionary.updateValue(imagePaths, forKey: searchTerm)
					}
					else {
						self.imageURLDictionary[searchTerm] = [imagePath]
					}
					NSUserDefaults.standardUserDefaults().setObject(self.imageURLDictionary, forKey: "searchURLs")

					// save image data
					if let imageData = UIImageJPEGRepresentation(image, 1.0) {
						do {
							try imageData.writeToFile(imagePath, options: .DataWritingAtomic)
						}
						catch {
							print(error)
						}
					}
				}
			}
		}
	}

	// MARK - Empty Cache

	func emptyMemoryCache() {
		cache.removeAllObjects()
	}

	func emptyDiskCacheForSearchTerm(searchTerm: String) {
		if let imagePaths = imageURLDictionary[searchTerm] {
			for unusedImagePath in imagePaths {
				deleteImageAtImagePath(unusedImagePath)
			}
		}
	}

	private func deleteImageAtImagePath(imagePath: String) {
		if NSFileManager.defaultManager().fileExistsAtPath(imagePath) {
			do {
				try NSFileManager.defaultManager().removeItemAtPath(imagePath)
			} catch {
				print("error deleting image from disk: \(error)")
			}
		}
	}

	// MARK: - Retrive image

	private func imageFromDiskCacheForURL(imageURL: NSURL) -> UIImage? {
		if isImageCachedToDisk(imageURL) {
			let directories = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
			if directories.count > 0 {
				if let urlString = imageURL.lastPathComponent {
					let documentDirectory = directories[0]
					let imagePath = documentDirectory.stringByAppendingString("/\(urlString)")
					if let diskImage = UIImage(contentsOfFile: imagePath) {
						cacheImageToMemory(diskImage, imageURL: imageURL)
						return diskImage
					}
				}
			}
		}
		return nil
	}

	private func keyForImageURL(imageURL: NSURL) -> String {
		return imageURL.absoluteString
	}

	private func imageForKey(key: String) -> UIImage? {
		if let cachedImage = cache.objectForKey(key) as? UIImage {
			return cachedImage
		}
		return nil
	}

	private func diskPathForImageURL(imageURL: NSURL) -> String? {
		let directories = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		if directories.count > 0 {
			if let urlString = imageURL.lastPathComponent {
				let documentDirectory = directories[0]
				return documentDirectory.stringByAppendingString("/\(urlString)")
			}
		}
		return nil
	}

	// MARK: - isImageCached

	private func isImageCachedToMemory(imageURL: NSURL) -> Bool {
		if let _ = imageForKey(keyForImageURL(imageURL)) {
			return true
		}
		return false
	}

	private func isImageCachedToDisk(imageURL: NSURL) -> Bool {
		if let imagePath = diskPathForImageURL(imageURL) {
			return NSFileManager.defaultManager().fileExistsAtPath(imagePath)
		}
		return false
	}
}
