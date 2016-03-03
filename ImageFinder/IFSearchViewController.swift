//
//  IFSearchViewController.swift
//  ImageFinder
//
//  Created by Subash Luitel on 2/25/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFSearchViewController: UITableViewController, UISearchBarDelegate {

	var recentSearches = [String]()
	var filteredRecentSearches = [String]()
	var searchBar = UISearchBar()
	let reuseIdentifier = "SearchCell"
	var delegate: IFSearchViewControllerDelegate?


	// MARK: - View Hirarchy

    override func viewDidLoad() {
        super.viewDidLoad()

		self.clearsSelectionOnViewWillAppear = false

		// add search bar to the navigatiopn bar
		navigationItem.titleView = searchBar
		searchBar.delegate = self

		// recent searches and filtered searches are same to begin with so that initially the tableview shows all the recent searches
		recentSearches = IFSearch.sharedInstance.recentSearches
		filteredRecentSearches = recentSearches

		registerForKeyboardNotifications()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		searchBar.becomeFirstResponder()
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		searchBar.resignFirstResponder()
	}


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRecentSearches.count
    }

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
		cell.textLabel?.text = filteredRecentSearches[indexPath.row]
		return cell
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Recent searches"
	}

	// MARK: - UITableViewDelegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let cell = tableView.cellForRowAtIndexPath(indexPath) {
			if let searchText = cell.textLabel?.text {
				dismissViewControllerAnimated(false, completion: { () -> Void in
					self.delegate?.searchViewControllerDidPressSearchButton(self, searchText: searchText)
				})
			}
		}
	}

	//MARK: - IBActions

	@IBAction func cancelButtonPresssed(sender: AnyObject) {
		dismissViewControllerAnimated(false, completion: nil)
	}


	// MARK: - Search Bar Delegate

	func searchBarSearchButtonClicked(searchBar: UISearchBar) {
		if let searchText = searchBar.text {
			NSUserDefaults.standardUserDefaults().setObject(recentSearches, forKey: "recentSearches")
			dismissViewControllerAnimated(false, completion: { () -> Void in
				self.delegate?.searchViewControllerDidPressSearchButton(self, searchText: searchText)
			})
		}
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		if searchText == "" {
			filteredRecentSearches = recentSearches
		}
		else {
			filteredRecentSearches = recentSearches.filter({ (searchItem) -> Bool in
				return searchItem.lowercaseString.containsString(searchText.lowercaseString)
			})
		}
		tableView.reloadData()
	}

	// MARK: - Helper Methods

	func registerForKeyboardNotifications() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
	}

	// MARK: - UIKeyboardNotifications

	func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
			tableView.contentInset.bottom = keyboardSize.height
		}
	}

	func keyboardWillHide(notification: NSNotification) {
		tableView.contentInset.bottom = 0
	}
}

protocol IFSearchViewControllerDelegate {
	func searchViewControllerDidPressSearchButton(searchViewController: IFSearchViewController, searchText: String)
}
