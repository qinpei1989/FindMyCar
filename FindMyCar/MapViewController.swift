//
//  MapViewController.swift
//  FindMyCar
//
//  Created by Pei Qin on 4/7/17.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var flagButton: UIButton!
    
    var calloutAccessoryButton: UIButton!
    var parkingLocation: ParkingLocation!
    var currentLocation: CLLocation!
    var currentPlacemark: CLPlacemark?
    var geocoder: CLGeocoder?
    var route: MKRoute? {
        didSet {
            if route == nil {
                calloutAccessoryButton.setTitle(NSLocalizedString("Route", comment: "Route"), for: .normal)
            } else {
                calloutAccessoryButton.setTitle(LocalizedString.cancelMessage, for: .normal)
            }
        }
    }

    @IBAction func backButtonTouched(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func arrowButtonTouched(_ sender: UIButton) {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func flagButtonTouched(_ sender: UIButton) {
        displayLocations()
    }
    
    /*
     * Display current user location and parking location simultaneously if possible.
     */
    func displayLocations() {
        let pLocation = parkingLocation.location
        // currentLocation can be updated at any time, so save its value first
        let current = currentLocation!
        
        let minLatitude = min(current.coordinate.latitude, pLocation.coordinate.latitude)
        let maxLatitude = max(current.coordinate.latitude, pLocation.coordinate.latitude)
        let minLongitude = min(current.coordinate.longitude, pLocation.coordinate.longitude)
        let maxLongitude = max(current.coordinate.longitude, pLocation.coordinate.longitude)
        
        print("minLat: \(minLatitude), maxLat: \(maxLatitude)")
        print("minLong: \(minLongitude), maxLong: \(maxLongitude)")
        
        var center = CLLocationCoordinate2D(latitude: minLatitude + (maxLatitude - minLatitude) / 2, longitude: minLongitude + (maxLongitude - minLongitude) / 2)
        let extraSpace = 1.5
        let span = MKCoordinateSpan(latitudeDelta: (maxLatitude - minLatitude) * extraSpace, longitudeDelta: (maxLongitude - minLongitude) * extraSpace)
        
        // If the map cannot display two locations at the same time, just show the parking location
        if span.longitudeDelta > 110 {
            center = CLLocationCoordinate2D(latitude: pLocation.coordinate.latitude, longitude: pLocation.coordinate.longitude)
        }
        
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    private func createAnnotation(fromParkingLocation location: ParkingLocation) -> MKAnnotation{
        let annotation = MKPointAnnotation()
        annotation.title = parkingLocation.placemark?.thoroughfare ?? NSLocalizedString("(Unknown Place)", comment: "(Unknown Place)")
        annotation.subtitle = location.placemark?.locality
        annotation.coordinate = location.location.coordinate
        return annotation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calloutAccessoryButton = UIButton(type: .roundedRect)
        calloutAccessoryButton.frame = CGRect(x: 0, y: 0, width: 80, height: 20)
        calloutAccessoryButton.setTitle(NSLocalizedString("Route", comment: "Route"), for: .normal)
        
        mapView.showsUserLocation = true
        displayLocations()
        
        let annotation = createAnnotation(fromParkingLocation: parkingLocation)
        mapView.addAnnotation(annotation)
        
        arrowButton.layer.cornerRadius = 5
        arrowButton.layer.masksToBounds = true
        
        flagButton.layer.cornerRadius = 5
        flagButton.layer.masksToBounds = true
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print(#function)
    
        if let location = userLocation.location {
            currentLocation = location
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Still use a blue dot to represent user's location
        if annotation === mapView.userLocation {
            return nil
        }
        // Use a pin to represent a parking location
        let identifier = "LocationAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = true
            pinView.rightCalloutAccessoryView = calloutAccessoryButton
            annotationView = pinView
        }
        annotationView?.annotation = annotation
        
        return annotationView
    }
    
    /* 
     * When callout button is tapped, draw a route from current location to parking location if possible
     */
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let fromPlacemark = MKPlacemark(coordinate: mapView.userLocation.coordinate)
        let toPlacemark = MKPlacemark(coordinate: parkingLocation.location.coordinate)
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.transportType = .any
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error != nil {
                print("Failed to draw routes")
                self.noRoutesAlert()
                return
            } else {
                if let r = self.route {
                    self.mapView.remove(r.polyline)
                    self.route = nil
                } else {
                    self.route = response?.routes[0]
                    self.mapView.add((self.route?.polyline)!, level: .aboveRoads)
                }
            }
        }
    }
    
    func noRoutesAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Cannot find a route", comment: "title of 'No Route' UIAlertController"),
                                      message: NSLocalizedString("No routes to your destination can be found at this time. ", comment: "message of 'No Route' UIAlertController"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: LocalizedString.okMessage, style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 8.0
        return renderer
    }
}

extension MapViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
