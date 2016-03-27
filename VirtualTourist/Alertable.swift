//
//  Alertable.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-27.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit

protocol Alertable {}

extension Alertable where Self: UIViewController {
    func alert(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
