//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-07.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import PromiseKit
import MapKit

class PhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    let flickrClient = FlickrClient.sharedInstance()
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    
        adjustFlowLayout(view.frame.size)
        
        let center =  CLLocationCoordinate2D(latitude: pin!.latitude as Double, longitude: pin!.longitude as Double)
        mapView.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView!.reloadData()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(pin!.photos.count)
        return pin!.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = pin!.photos[indexPath.item]
        let activityOverlay = ActivityOverlay(alpha: 0.7, activityIndicatorColor: UIColor.whiteColor(), overlayColor: UIColor.blackColor())
        
        if (photo.image != nil) {
            cell.imageView.image = photo.image
        } else {
            
            activityOverlay.overlay(cell)
            
            firstly {
                flickrClient.getImage(url: photo.imagePath!)
            }.then { image -> Void in
                photo.image = image
                cell.imageView.image = image
                activityOverlay.removeOverlay()
            }.error { error in
                
                // TODO: handle flickr error
                
            }
        }
        
        return cell
    }
    
    /* adjust flow layout based on size of the screen. typically portrait vs. landscape mode*/
    func adjustFlowLayout(size: CGSize) {
        guard let flowLayout = flowLayout else {
            return
        }
        
        let space: CGFloat = 1.5
        let dimension:CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 7.0 :  (size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }

  
}
