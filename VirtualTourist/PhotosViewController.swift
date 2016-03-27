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

class PhotosViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, Alertable {
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionButton: UIButton!
    
    var selectedIndexPaths = [Int: NSIndexPath]()
    let flickrClient = FlickrClient.sharedInstance()
    var pin: Pin!
    
    // MARK - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
       
        initCollectionView()
        initMapView()
        
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView!.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if pin.photos.count == 0 {
            showNoPicturesView()
        }
    }
    
    @IBAction func newCollectionTouchUp(sender: AnyObject) {
        
        if selectedIndexPaths.count > 0 {
            
            selectedIndexPaths.forEach { (index, indexPath) in
                sharedContext.deleteObject(pin.photos[index])
            }
        
            saveContext()
            collectionView.deleteItemsAtIndexPaths(Array(selectedIndexPaths.values))
            selectedIndexPaths.removeAll()
            actionButton.setTitle(determineButtonText(), forState: UIControlState.Normal)
            
            return
        }
        
        //disable button
        actionButton.enabled = false
        
        // overlay view
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: collectionView.frame.width, height: collectionView.frame.height))
        let overlayView = UIView(frame: frame);
        overlayView.backgroundColor = UIColor.whiteColor()
        collectionView.addSubview(overlayView)
        
        UIView.animateWithDuration(2,
            animations: { () -> Void in
                overlayView.alpha = 0
            },
            completion: { (result) -> Void in
                overlayView.removeFromSuperview()
        })

        pin.photos.forEach{ photo in
            sharedContext.deleteObject(photo)
        }
        
        pin.flickrPage = (pin.flickrPage as Int) + 1
        saveContext()
        self.collectionView.reloadData()
        
        // refetch new data
        firstly {
            flickrClient.getImageUrls(latitude: pin.latitude as Double, longitude: pin.longitude as Double, flickrPage: pin.flickrPage as Int)
        }.then { imageCollection -> Void in
            
            if imageCollection.count == 0 {
                self.showNoPicturesView()
                return
            }
            
            // 1) persist the fetched image data
            imageCollection.forEach { dict in
                _ = Photo(dictionary: dict, pin: self.pin, context: self.sharedContext)
                
            }
            self.saveContext()
            self.collectionView.reloadData()
            self.actionButton.enabled = true
        }
        
        
    }
    
    // MARK: Helper functions
    
    func initCollectionView() {
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        adjustFlowLayout(view.frame.size)
    }
    
    func initMapView() {
        let center =  CLLocationCoordinate2D(latitude: pin!.latitude as Double, longitude: pin!.longitude as Double)
        mapView.region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
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
    
    
    func showNoPicturesView() {
        collectionView.addSubview(createNoPicturesView(collectionView))
    }
    
    func createNoPicturesView(view: UIView) -> UIView {
        let noPicturesView = UIView()
        noPicturesView.backgroundColor = UIColor.whiteColor()
        noPicturesView.alpha = 1
        noPicturesView.frame.size.height = view.frame.height
        noPicturesView.frame.size.width = view.frame.width
        noPicturesView.frame.origin.x = 0
        noPicturesView.frame.origin.y = 0
        
        let label = UILabel()
        label.text = "No Pictures for this pin"
        label.textAlignment = NSTextAlignment.Center
        label.textColor = UIColor.blackColor()
        label.sizeToFit()
        label.center = CGPoint(x: (noPicturesView.frame.width / 2), y: noPicturesView.frame.height / 2)
        noPicturesView.addSubview(label)
        
        print("view center = x: \(label.center.x) y: \(label.center.y)")
        
        return noPicturesView;
    }
    
    
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
        return selectedIndexPaths.count > 0 ? "Remove Selected Pictures" : "New Collection"
    }
    
    // MARK: Collection View delegate functions
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.addSubview(createSelectionOverlay(cell))
        selectedIndexPaths[indexPath.item] = indexPath
        
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        cell.imageView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        
        selectedIndexPaths.removeValueForKey(indexPath.item)
        
        actionButton.setTitle(determineButtonText(), forState: .Normal)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = pin.photos[indexPath.item]
        let activityOverlay = ActivityOverlay(alpha: 0.7, activityIndicatorColor: UIColor.blackColor(), overlayColor: UIColor.whiteColor())
        
        if selectedIndexPaths[indexPath.item] != nil {
            cell.imageView.addSubview(createSelectionOverlay(cell))
        } else if cell.imageView.subviews.count >  0 {
            cell.imageView.subviews.forEach { sub in
                sub.removeFromSuperview()
            }
        }

        if (photo.image != nil) {
            cell.imageView.image = photo.image
        } else {
            
            activityOverlay.overlay(cell)
            
            firstly {
                flickrClient.getImage(url: photo.imagePath)
            }.then { image -> Void in
                photo.image = image
                cell.imageView.image = image
                activityOverlay.removeOverlay()
            }.error { error in
                self.alert("There was an error fetching an image from Flickr")
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
  
}
