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
import CoreData

class PhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionButton: UIButton!
    
    var selectedPhotos = [String: Photo]()
    let flickrClient = FlickrClient.sharedInstance()
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        adjustFlowLayout(view.frame.size)
        
        let center =  CLLocationCoordinate2D(latitude: pin!.latitude as Double, longitude: pin!.longitude as Double)
        mapView.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
        
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView!.reloadData()
    }
    
    @IBAction func newCollectionTouchUp(sender: AnyObject) {
        
        if selectedPhotos.count > 0 {
            
            // we are in delete mode
            selectedPhotos.forEach { (_, photo) in
                print(photo.imagePath)
                photo.image = nil
                sharedContext.deleteObject(photo)
            }
            
            saveContext()
            collectionView.reloadData()
            return
        }
        
        
        // invalidate all of the cache in the photos and delete them from core data
        pin.photos.forEach{ photo in
            photo.image = nil
            sharedContext.deleteObject(photo)
        }
        
        pin.flickrPage = (pin.flickrPage as Int) + 1
        saveContext()
        self.collectionView.reloadData()
        
        // refetch new data
        firstly {
            flickrClient.getImageUrls(latitude: pin.latitude as Double, longitude: pin.longitude as Double, flickrPage: pin.flickrPage as Int)
            }.then { imageCollection -> Void in
                
                // 1) persist the fetched image data
                imageCollection.forEach { dict in
                    _ = Photo(dictionary: dict, pin: self.pin, context: self.sharedContext)
                    
                }
                self.saveContext()
                self.collectionView.reloadData()
        }
        
        
    }
    
    // MARK: Helper functions
    
    // create overlay view to be added to photo cell
    func createSelectionOverlay(cell: PhotoCollectionViewCell) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.whiteColor()
        overlay.alpha = 0.6
        overlay.frame.size.height = cell.imageView.frame.height
        overlay.frame.size.width = cell.imageView.frame.width
        overlay.frame.origin.x = 0
        overlay.frame.origin.y = 0
        
        return overlay
    }
    
    func determineButtonText() -> String {
        return selectedPhotos.count > 0 ? "Remove Selected Pictures" : "New Collection"
    }
    
    // MARK: Collection View delegate functions
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.addSubview(createSelectionOverlay(cell))
        selectedPhotos[cell.photo!.imagePath! ] = cell.photo
        
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        
        selectedPhotos.removeValueForKey(cell.photo!.imagePath!)
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = pin.photos[indexPath.item]
        let activityOverlay = ActivityOverlay(alpha: 0.7, activityIndicatorColor: UIColor.blackColor(), overlayColor: UIColor.whiteColor())
        
        if selectedPhotos[photo.imagePath!] != nil {
            cell.imageView.addSubview(createSelectionOverlay(cell))
        } else if cell.imageView.subviews.count >  0 {
            cell.imageView.subviews.forEach { sub in
                sub.removeFromSuperview()
            }
        }

        cell.photo = photo

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
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
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
