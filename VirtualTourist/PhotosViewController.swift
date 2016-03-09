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
    @IBOutlet weak var mapImage: UIImageView!
    
    
    let flickrClient = FlickrClient.sharedInstance()
    
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        adjustFlowLayout(view.frame.size)
        let options = MKMapSnapshotOptions()
        let center =  CLLocationCoordinate2D(latitude: pin!.latitude as Double, longitude: pin!.longitude as Double)
        options.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5))
        let mapSnapShotter = MKMapSnapshotter(options: options)
        mapSnapShotter.startWithCompletionHandler { (snapshot, error) -> Void in
            if let error = error {
                // TODO: print and do nothing for now.
                print (error)
                return
            }
            
            let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            //self.mapImage.image = snapshot!.image
            
            let image = snapshot!.image
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.drawAtPoint(CGPoint.zero)
            
            var point = snapshot!.pointForCoordinate(center)

            point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
            point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)

            pin.image!.drawAtPoint(point)
            
            self.mapImage.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            
        }
        
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
        let dimension:CGFloat = size.width >= size.height ? (size.width - (5 * space)) / 6.0 :  (size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }

  
}
