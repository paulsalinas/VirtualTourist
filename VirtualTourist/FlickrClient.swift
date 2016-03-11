//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-06.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import SwiftyJSON


class FlickrClient {

    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "70dd37f1b1c6c264c7b3ce5a10c66f0b"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    let PER_PAGE = 21
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }

    func getImageUrls(latitude latitude: Double, longitude: Double, flickrPage: Int = 1) -> Promise<[[String: AnyObject]]> {
        let methodArguments:[NSObject: AnyObject] = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitude: latitude, longitude: longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": PER_PAGE,
            "page": flickrPage
        ]
        
        let urlString = BASE_URL
        
        return firstly {
            NSURLSession.POST(urlString, formData: methodArguments)
        }.then { data in
            let json = JSON(data: data)
            print(json)
            let photos = json["photos"]["photo"].arrayValue
            let urls: [[String: AnyObject]] = photos.map {
                [
                    "id": $0["id"].intValue,
                    "imagePath": $0["url_m"].stringValue
                ]
            }
            
            print(urls)
            return Promise<[[String: AnyObject]]>(urls)
        }
    }
    
    func getImage(url url: String) -> Promise<UIImage?> {
        return firstly {
            NSURLSession.GET(url)
        }.then { data in
            return Promise<UIImage?>(UIImage(data: data))
        }
    }
    
    func createBoundingBoxString(latitude latitude: Double, longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}
