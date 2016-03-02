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
        
        if NSUserDefaults.standardUserDefaults().boolForKey("savedAppState") {
            let latitudeCenter = NSUserDefaults.standardUserDefaults().doubleForKey("latitudeCenter")
            let longitudeCenter = NSUserDefaults.standardUserDefaults().doubleForKey("longitudeCenter")
            let longitudeSpan = NSUserDefaults.standardUserDefaults().doubleForKey("longitudeSpan")
            let latitudeSpan = NSUserDefaults.standardUserDefaults().doubleForKey("latitudeSpan")
            
            let centerCoordinate =  CLLocationCoordinate2D(latitude: latitudeCenter, longitude: longitudeCenter)
            let span = MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan)
            
            let altitude = NSUserDefaults.standardUserDefaults().doubleForKey("altitude")
            let pitch = NSUserDefaults.standardUserDefaults().objectForKey("pitch") as! CGFloat
            let heading = NSUserDefaults.standardUserDefaults().doubleForKey("heading")
            
            mapView.region = MKCoordinateRegion(center: centerCoordinate, span: span)
            mapView.setCamera(MKMapCamera(lookingAtCenterCoordinate: centerCoordinate, fromDistance: altitude, pitch: pitch, heading: heading), animated: false)
        }

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

        let region = mapView.region

        NSUserDefaults.standardUserDefaults().setDouble(region.center.latitude, forKey: "latitudeCenter")
        NSUserDefaults.standardUserDefaults().setDouble(region.center.longitude, forKey: "longitudeCenter")
        
        NSUserDefaults.standardUserDefaults().setDouble(region.span.latitudeDelta, forKey: "latitudeSpan")
        NSUserDefaults.standardUserDefaults().setDouble(region.span.longitudeDelta, forKey: "longitudeSpan")
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "savedAppState")
        
        NSUserDefaults.standardUserDefaults().setDouble(mapView.camera.altitude, forKey: "altitude")
        NSUserDefaults.standardUserDefaults().setObject(mapView.camera.pitch, forKey: "pitch")
        NSUserDefaults.standardUserDefaults().setDouble(mapView.camera.heading, forKey: "heading")

    }
    

}

