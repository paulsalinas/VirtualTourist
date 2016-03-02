//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-02-27.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
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
    }
    
    // MARK: - Gesture Handler Functions
    
    func handleLongTouch(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapView.convertPoint(recognizer.locationInView(mapView), toCoordinateFromView: mapView)
            
            mapView.addAnnotation(annotation)
        }
    }
    
    func handleSingeTap(recognizer: UITapGestureRecognizer) {
        let annotation = (recognizer.view as! MKPinAnnotationView).annotation!
        print(annotation.coordinate)
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
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
            
            let altitude = regionDictionary["altitude"] as! CLLocationDistance
            let pitch = regionDictionary["pitch"] as! CGFloat
            let heading = regionDictionary["heading"] as! CLLocationDirection
            
            let savedCamera = MKMapCamera(lookingAtCenterCoordinate: center, fromDistance: altitude, pitch: pitch, heading: heading)
            mapView.setCamera(savedCamera, animated: animated)
        }
    }
}

