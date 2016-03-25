//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-02-27.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import PromiseKit


class MapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var instructionView: UILabel!
    var isEditingPins: Bool!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    
    let flickrClient = FlickrClient.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Configure tap recognizer */
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongTouch:")
        longPressGestureRecognizer.minimumPressDuration = 1
        longPressGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        mapView.showsCompass = true
        
        mapView.delegate = self
        
        restoreMapState(false)
        
        addPinsToMap(fetchAllPins())
        
        instructionView = UILabel()
        instructionView.backgroundColor = UIColor.redColor()
        view.addSubview(instructionView)
        instructionView.frame.origin.y = view.frame.height
        instructionView.frame.origin.x = 0
        instructionView.frame.size.width = view.frame.width
        instructionView.frame.size.height = view.frame.height / 6
        instructionView.text = "Tap Pins to Delete"
        instructionView.textAlignment = NSTextAlignment.Center
        instructionView.textColor = UIColor.whiteColor()
        
        isEditingPins = false
    }
    
    @IBAction func editBtnTouchUp(sender: AnyObject) {
        
        let animationSpeed = 0.3
        let y = mapView.frame.origin.y
        
        if (!isEditingPins) {
            UIView.animateWithDuration(animationSpeed, animations: {
                self.mapView.frame.origin.y = y - self.instructionView.frame.height
                self.instructionView.frame.origin.y = self.instructionView.frame.origin.y - self.instructionView.frame.height
            })
            
            isEditingPins = true
            editBtn.title = "Done"
            
        } else {
            UIView.animateWithDuration(animationSpeed, animations: {
                self.mapView.frame.origin.y = y + self.instructionView.frame.height
                self.instructionView.frame.origin.y = self.instructionView.frame.origin.y + self.instructionView.frame.height
            })
            
            isEditingPins = false
            editBtn.title = "Edit"
        }
    }
    
    // add array of pins to the map view
    func addPinsToMap(pins: [Pin]) {
        let annotations = pins.map { pin -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude as Double, longitude: pin.longitude as Double)
            return annotation
        }
        
        annotations.forEach { a in
            mapView.addAnnotation(a)
        }
    }

    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func fetchPin(longitude longitude: NSNumber, latitude: NSNumber) -> Pin? {
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.predicate = NSPredicate(format: "longitude == %@ AND latitude == %@", longitude, latitude)
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest).first as! Pin?
        } catch _ {
            return nil
        }
    }
    

    // MARK: - Gesture Handler Functions
    
    func handleLongTouch(recognizer: UILongPressGestureRecognizer) {
        guard isEditingPins != true else {
            return
        }
        
        if recognizer.state == UIGestureRecognizerState.Began {
            
            let annotation = MKPointAnnotation()
            let coordinate = mapView.convertPoint(recognizer.locationInView(mapView), toCoordinateFromView: mapView)
            let newPin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: sharedContext)
            saveContext()
            
            annotation.coordinate = coordinate
            
            firstly {
                flickrClient.getImageUrls(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }.then { imageCollection -> Void in
                
                // 1) persist the fetched image data
                imageCollection.forEach { dict in
                    _ = Photo(dictionary: dict, pin: newPin, context: self.sharedContext)
                    
                }
                self.saveContext()
                
                // 2) fetch and store each image
                newPin.photos.forEach { photo in
                    
                    firstly {
                        self.flickrClient.getImage(url: photo.imagePath)
                    }.then { image in
                        photo.image = image
                    }.error { error in
                      // TODO: handle flickr client error here
                    }
                   
                }
            }.error { error in
                // TODO: handle flickr client error here
            }
            
            mapView.addAnnotation(annotation)
        }
    }
    
    func handleSingeTap(recognizer: UITapGestureRecognizer) {
        guard let annotation = (recognizer.view as! MKPinAnnotationView).annotation else {
            return
        }
        
        guard let pin = fetchPin(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude) else {
            return
        }
        
        if isEditingPins == true {
            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(annotation)
            saveContext()
            return
        }
        
        let controller = storyboard?.instantiateViewControllerWithIdentifier("PhotosViewController") as! PhotosViewController
        controller.pin = pin
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
    // MARK: - Map Delegate Functions
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.animatesDrop = true
            pinView!.draggable = true
            
            let longPressGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleSingeTap:")
            longPressGestureRecognizer.numberOfTapsRequired = 1
            longPressGestureRecognizer.delegate = self
            
            pinView!.addGestureRecognizer(longPressGestureRecognizer)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapState()
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if (oldState == MKAnnotationViewDragState.None && newState == MKAnnotationViewDragState.Starting) {
            
            // delete the annotation view
            let coordinate = view.annotation!.coordinate
            let pin = fetchPin(longitude: coordinate.longitude , latitude: coordinate.latitude)!
            sharedContext.deleteObject(pin)
            saveContext()
        } else if (newState == MKAnnotationViewDragState.Ending && newState != MKAnnotationViewDragState.Canceling) {
            
            // add the moved annotation view
            let coordinate = view.annotation!.coordinate
            let newPin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: sharedContext)
            firstly {
                flickrClient.getImageUrls(latitude: coordinate.latitude, longitude: coordinate.longitude)
                }.then { imageCollection -> Void in
                    
                    // 1) persist the fetched image data
                    imageCollection.forEach { dict in
                        _ = Photo(dictionary: dict, pin: newPin, context: self.sharedContext)
                        
                    }
                    self.saveContext()
                    
                    // 2) fetch and store each image
                    newPin.photos.forEach { photo in
                        
                        firstly {
                            self.flickrClient.getImage(url: photo.imagePath)
                            }.then { image in
                                photo.image = image
                            }.error { error in
                                // TODO: handle flickr client error here
                        }
                        
                    }
                }.error { error in
                    // TODO: handle flickr client error here
            }
            
            saveContext()
        }
    }
    
    // MARK: - Save the zoom level helpers
    
    // Here we use the same filePath strategy as the Persistent Master Detail
    // A convenient property
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapState() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta,
            "altitude": mapView.camera.altitude,
            "pitch": mapView.camera.pitch,
            "heading": mapView.camera.heading
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapState(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
            
            let altitude = regionDictionary["altitude"] as! CLLocationDistance
            let pitch = regionDictionary["pitch"] as! CGFloat
            let heading = regionDictionary["heading"] as! CLLocationDirection
            
            let savedCamera = MKMapCamera(lookingAtCenterCoordinate: center, fromDistance: altitude, pitch: pitch, heading: heading)
            mapView.setCamera(savedCamera, animated: animated)
        }
    }
}

