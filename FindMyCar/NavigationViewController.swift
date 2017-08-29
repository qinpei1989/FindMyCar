//
//  NavigationViewController.swift
//  FindMyCar
//
//  Created by Pei Qin on 4/7/17.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import UIKit
import CoreLocation

class NavigationViewController: UIViewController {
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var compassImage: UIImageView!
    @IBOutlet weak var mapButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var locationManager: CLLocationManager!
    var parkingLocation: ParkingLocation!
    var currentLocation: CLLocation?
    var currentHeading: CLLocationDirection = 0 // default points to north
    var geocoder: CLGeocoder!
    let lengthFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    @IBAction func backButtonTouched(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("latitude: \(parkingLocation.location.coordinate.latitude), longitude: \(parkingLocation.location.coordinate.longitude)")
        
        distanceLabel.text = NSLocalizedString("Calculating your distance...", comment: "Calculating your distance...")
        accuracyLabel.isHidden = true
        mapButton.isEnabled = false
        activityIndicator.startAnimating()
        startLocationManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLocationManager()
    }
    
    func startLocationManager() {
        print("start location manager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopLocationManager() {
        print("stop location manager")
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
    func updateUI() {
        if let location = currentLocation {
            let distance = location.distance(from: parkingLocation.location)
            distanceLabel.text = lengthFormatter.string(fromMeters: distance)
            distanceLabel.isHidden = false
            accuracyLabel.text = NSLocalizedString("Accuracy: ~", comment: "Accuracy: ~") + lengthFormatter.string(fromMeters: location.horizontalAccuracy)
            accuracyLabel.isHidden = false
            mapButton.isEnabled = true
            activityIndicator.stopAnimating()
            
            let bearingBetweenTwoLocationsInRadians = Utils.getBearingBetweenTwoPoints(location1: location, location2: parkingLocation.location)
            let currentCourseInRadians = Utils.degreesToRadians(degrees: currentHeading)
            
            /*
             * If bearingBetweenTwoLocationsInRadians is pi/2, it means parking location is on the east.
             * If currentCourseInRadians is -pi/2, it means you are heading towards west.
             * Therefore, we get pi/2-(-pi/2) = pi, which means parking location is right behind you.
             */
            let arrowRotationAngle = bearingBetweenTwoLocationsInRadians - currentCourseInRadians
            
            UIView.animate(withDuration: 0.5, animations: {
                self.compassImage.transform = CGAffineTransform(rotationAngle: CGFloat(arrowRotationAngle))
            })
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMap" {
            let vc = segue.destination as! MapViewController
            vc.parkingLocation = parkingLocation
            vc.currentLocation = currentLocation
            vc.geocoder = geocoder
        }
    }

}

extension NavigationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        currentLocation = Utils.transformLocation(fromLocation: newLocation)
        updateUI()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
        if currentLocation != nil {
            updateUI()
        }
    }
}

extension NavigationViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
