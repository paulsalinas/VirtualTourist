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
        
        mapView.delegate = self
    }
    
    // MARK: - Gesture Handler Functions
    
    func handleLongTouch(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
        
            let coordinates = mapView.convertPoint(recognizer.locationInView(mapView), toCoordinateFromView: mapView)
            print(coordinates)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - Map Delegate Functions
    
    // taken from stack answer: http://stackoverflow.com/a/34967157
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        var i = -1;
        for view in views {
            i++;
            if view.annotation is MKUserLocation {
                continue;
            }
            
            // Check if current annotation is inside visible map rect, else go to next one
            let point:MKMapPoint  =  MKMapPointForCoordinate(view.annotation!.coordinate);
            if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point)) {
                continue;
            }
            
            let endFrame:CGRect = view.frame;
            
            // Move annotation out of view
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
            
            // Animate drop
            let delay = 0.03 * Double(i)
            UIView.animateWithDuration(0.5, delay: delay, options: UIViewAnimationOptions.CurveEaseIn, animations:{() in
                view.frame = endFrame
                
                // Animate squash
                }, completion:{(Bool) in
                    UIView.animateWithDuration(0.05, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                        view.transform = CGAffineTransformMakeScale(1.0, 0.6)
                        
                        }, completion: {(Bool) in
                            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:{() in
                                view.transform = CGAffineTransformIdentity
                                }, completion: nil)
                    })
                    
            })
        }
        
    }

}

