//
//  IFSearch.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/25/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFSearch: NSObject {

	static let sharedInstance = IFSearch()
	var recentSearches = [String]()

	private override init() {
		if let searches = NSUserDefaults.standardUserDefaults().arrayForKey("recentSearches") as? [String] {
			recentSearches = searches
		}
	}

	func addNewSearch(searchTerm: String) {

		// add search to first of the array
		// if the search exists bring it to front
		if let index = recentSearches.indexOf({$0.lowercaseString == searchTerm.lowercaseString}) {
			recentSearches.removeAtIndex(index)
		}
		recentSearches.insert(searchTerm, atIndex: 0)

		// keep images on disk only for 10 recent searches
		// for every image added to search array the images related to 10th item will be deleted
		if recentSearches.count > 10 {
			IFImageCache.sharedCache.emptyDiskCacheForSearchTerm(recentSearches[10])
		}
		NSUserDefaults.standardUserDefaults().setObject(recentSearches, forKey: "recentSearches")
	}
}
