//
//  IFImagesViewController.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/23/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFImagesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, IFSearchViewControllerDelegate {

	@IBOutlet weak var imageCollectionView: UICollectionView!
	var images = [NSURL]()
	let reuseIdentifier = "ImageCell"
	let imageDownloader = IFImageDownloader.sharedInstance
	var isViewScrolling = false
	var isCollectionReloadPending = false
	var loadingImages = false
	var initialView = UIView()

	@IBOutlet weak var searchButton: UIButton!


	// MARK: - View Hirarchy

    override func viewDidLoad() {
        super.viewDidLoad()
		addViewsForEmptyCollectionView()
    }

	// MARK: - UICollectionViewDataSource

	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		initialView.hidden = images.count > 0
		return images.count
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! IFImageCell
		if images.count > indexPath.row {
			let imageURL = images[indexPath.item]
			cell.tag = indexPath.item

			// load cell image
			cell.loadImage(imageURL)
		}
		return cell
	}

	func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		var loadMoreView = UICollectionReusableView()
		if kind == UICollectionElementKindSectionFooter {
			loadMoreView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadMoreView", forIndexPath: indexPath)
		}
		return loadMoreView
	}

	// MARK: - UIScrollViewDelegate

	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		isViewScrolling = false

		// if collection view fetched new page of images reload it after it stops decelerating
		if isCollectionReloadPending {
			imageCollectionView.reloadData()
			isCollectionReloadPending = false
		}
	}

	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		isViewScrolling = true
	}


	// MARK: - UICollectionViewLayout

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		let width = (CGRectGetWidth(collectionView.bounds) - 6) / 3
		let height = width * 4 / 3
		return CGSizeMake(width, height)
	}

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 3.0
	}

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 2.0
	}

	func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
		if !loadingImages {
			loadNextPage()
		}
	}

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		if imageDownloader.currentPage < imageDownloader.maximumPages {
			return CGSizeMake(0, 100)
		}
		return CGSizeMake(0, 0)
	}

	// MARK: - Image Load Methods

	func loadImages(searchText: String) {
		MBProgressHUD.showHUDAddedTo(view, animated: true)
		IFImageDownloader.sharedInstance.findImagesWithSearchTerm(searchText) { (objects, error) -> Void in
			MBProgressHUD.hideHUDForView(self.view, animated: true)
			if let theError = error {
				let message = "Could not load images for the search query '\(searchText)' with error: \(theError.localizedDescription)"
				self.showErrorAlertWithMessage(message)
			}
			else if let theObjects = objects {
				self.images = theObjects
				IFImageCache.sharedCache.emptyMemoryCache()
				dispatch_async(dispatch_get_main_queue(),{
					self.navigationItem.title = searchText
					self.imageCollectionView.reloadData()
				})
			}
			else {
				let message = "Could not load images for the search query '\(searchText)'"
				self.showErrorAlertWithMessage(message)
			}
		}
	}

	func loadNextPage() {
		loadingImages = true
		imageDownloader.findImagesForNextPage { (objects, error) -> Void in
			if let moreImages = objects {
				self.images += moreImages

				// reload collection view only if it is not scrolling
				if !self.isViewScrolling {
					self.imageCollectionView.reloadData()
					self.isCollectionReloadPending = false
				}
				else {
					self.isCollectionReloadPending = true
				}
			} else {
				var message = "Could not load next page of images"
				if let errorMessage = error?.localizedDescription {
					message = "Could not load next page of images with error: \(errorMessage)"
				}
				self.showErrorAlertWithMessage(message)
			}
			self.loadingImages = false
		}
	}


	// MARK: - IFSearchViewControllerDelegate

	func searchViewControllerDidPressSearchButton(searchViewController: IFSearchViewController, searchText: String) {
		loadImages(searchText)
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ShowSearchView" {
			if let destinationNavigation = segue.destinationViewController as? UINavigationController {
				if destinationNavigation.viewControllers.count > 0 {
					if let searchVC = destinationNavigation.viewControllers[0] as? IFSearchViewController {
						searchVC.delegate = self
					}
				}
			}
		}
    }

	// MARK: - IBActions

	@IBAction func searchButtonPressed(sender: AnyObject) {
		performSegueWithIdentifier("ShowSearchView", sender: self)
	}

	// MARK: - Helpers

	func addViewsForEmptyCollectionView() {

		// Add initial view to collection view
		if let initialViews = NSBundle.mainBundle().loadNibNamed("IFEmptyImagesView", owner: self, options: nil) {
			if let theView = initialViews[0] as? UIView {
				initialView = theView
				initialView.frame = imageCollectionView.frame
				self.imageCollectionView.addSubview(initialView)
				initialView.hidden = true
			}
		}
		customizeSearchButton()
	}

	func showErrorAlertWithMessage(message: String) {
		let alertController = UIAlertController(title: "Uh oh!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
		let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
		alertController.addAction(cancelAction)
		self.presentViewController(alertController, animated: true, completion: nil)
	}

	func customizeSearchButton() {

		// Customize the search button
		searchButton.layer.borderWidth = 1.0
		searchButton.layer.cornerRadius = 20
		searchButton.layer.borderColor = UIColor.blueColor().CGColor
		searchButton.layer.masksToBounds = true
	}

}
