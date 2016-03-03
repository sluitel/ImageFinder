//
//  IFImageDownloader.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/23/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFImageDownloader: NSObject {

	var downloadTask: NSURLSessionDownloadTask?
	var dataTask: NSURLSessionDataTask?
	var currentSearch = String()
	var currentPage = 0
	var maximumPages = 0

	static let sharedInstance = IFImageDownloader()

	// MARK: - Download Image

	func downloadImageWithURL(imageURL: NSURL, completion: (image: UIImage?, error: NSError?) -> Void) -> NSURLSessionDownloadTask? {
		let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfiguration.allowsCellularAccess = true
		sessionConfiguration.timeoutIntervalForRequest = 30.0;
		sessionConfiguration.timeoutIntervalForResource = 60.0;
		let session = NSURLSession(configuration: sessionConfiguration)

		downloadTask = session.downloadTaskWithURL(imageURL, completionHandler: { (downloadedURL: NSURL?, response: NSURLResponse?, error: NSError?) -> Void in

			if let theURL = downloadedURL {
				if let imageData = NSData(contentsOfURL: theURL) {
					if let theImage = UIImage(data: imageData) {

						// resize downloaded image
						let resizedImage = IFImageResizer.resizeImageToThumbnail(theImage, thumbnailWidth: 400)

						// Cache downloaded image
						IFImageCache.sharedCache.cacheImage(resizedImage, imageURL: imageURL, searchTerm: self.currentSearch)

						dispatch_async(dispatch_get_main_queue(),{
							completion(image: resizedImage, error: nil)
						})
					}
				}
			}
		})
		if let theTask = downloadTask {
			theTask.resume()
		}
		return downloadTask
	}

	// MARK: - Fetch Images

	func findImagesWithSearchTerm(searchTerm: String, completion: (objects: [NSURL]?, error: NSError?) -> Void) {
		currentSearch = searchTerm
		currentPage = 1
		IFSearch.sharedInstance.addNewSearch(searchTerm)
		findImagesWithSearchTerm(searchTerm, page: 1, completion: completion)
	}

	func findImagesForNextPage(completion: (objects: [NSURL]?, error: NSError?) -> Void) {
		currentPage++
		findImagesWithSearchTerm(currentSearch, page: currentPage, completion: completion)
	}

	private func findImagesWithSearchTerm(searchTerm: String, page: Int, completion: (objects: [NSURL]?, error: NSError?) -> Void) {

		if let modifiedSearchTerm = searchTerm.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())  {
			let flickerAPIString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&format=json&nojsoncallback=1&per_page=30&extras=m_dims,url_o&page=\(page)&text=\(modifiedSearchTerm)"
			if let flickerURL = NSURL(string: flickerAPIString ) {

				let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
				sessionConfiguration.allowsCellularAccess = true
				sessionConfiguration.HTTPAdditionalHeaders = ["Accept" : "application/json"]
				sessionConfiguration.timeoutIntervalForRequest = 30.0;
				sessionConfiguration.timeoutIntervalForResource = 60.0;
				
				let session = NSURLSession(configuration: sessionConfiguration)
				dataTask = session.dataTaskWithURL(flickerURL, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

					if let imagesData = data {
						do {
							// serialize JSON
							let jsonArray = try NSJSONSerialization.JSONObjectWithData(imagesData, options:[])
							if let photosInfoDic = (jsonArray["photos"] as? [String : AnyObject]){
								if let numberOfPages = photosInfoDic["pages"] as? Int {
									self.maximumPages = numberOfPages
								}
								if let photoArray = photosInfoDic["photo"] as? [[String : AnyObject]] {
//                                    print(photoArray)

									// create photoArray as [NSURL]
									let photoURLArray = photoArray.map({ (photoDictionary) -> NSURL in
                                        let _ = IFPhoto(flickrDictionary: photoDictionary)
										return self.getImageURLFromJsonData(photoDictionary)
									})

									// completion in main thread
									dispatch_async(dispatch_get_main_queue(),{
										completion(objects: photoURLArray, error: error)
									})
								}
								else {
									dispatch_async(dispatch_get_main_queue(),{
										completion(objects: nil, error: error)
									})
								}
							}
							else {
								dispatch_async(dispatch_get_main_queue(),{
									completion(objects: nil, error: error)
								})
							}
						}
						catch {
							dispatch_async(dispatch_get_main_queue(),{
								completion(objects: nil, error: ((error as Any) as! NSError))
							})
						}
					}
					else {
						dispatch_async(dispatch_get_main_queue(),{
							completion(objects: nil, error: error)
						})
					}
				})

				// resume data task
				if let theDataTask = dataTask {
					theDataTask.resume()
				}
			}
			else {
				completion(objects: nil, error: nil)
			}
		}
	}

	private func getImageURLFromJsonData(jsonData: [String: AnyObject]) -> NSURL {
		var imageURL = NSURL()
		if let farm = jsonData["farm"] {
			if let server = jsonData["server"] {
				if let id = jsonData["id"] {
					if let secret = jsonData["secret"] {
						let urlString = "https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret).jpg"
						if let theURL = NSURL(string: urlString) {
							imageURL = theURL
						}
					}
				}
			}
		}
		return imageURL
	}
}
