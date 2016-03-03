//
//  IFPhoto.swift
//  ImageFinder
//
//  Created by Subash Luitel on 3/2/16.
//  Copyright © 2016 Luitel. All rights reserved.
//

import UIKit

class IFPhoto: NSObject {

    var url = NSURL()
    var height = CGFloat()
    var width = CGFloat()
    
    init(flickrDictionary: [String : AnyObject]) {
        if let farm = flickrDictionary["farm"], server = flickrDictionary["server"], id = flickrDictionary["id"], secret = flickrDictionary["secret"] {
            let urlString = "https://farm\(farm).static.flickr.com/\(server)/\(id)_\(secret).jpg"
            if let theURL = NSURL(string: urlString) {
                url = theURL
            }
        }
        if let imageWidth = flickrDictionary["width_o"] {
            print(imageWidth)
        }
        else {
            print("no width")
            print(flickrDictionary)
        }
    }
}
