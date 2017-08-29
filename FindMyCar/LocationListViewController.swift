//
//  ViewController.swift
//  FindMyCar
//
//  Created by Pei Qin on 4/6/17.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var parkButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var deleteAllButton: UIBarButtonItem!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var parkButtonInstructionLabel: UILabel!
    
    var managedObjectContext: NSManagedObjectContext!
    var parkingLocations = [ParkingLocation]()
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var isLocating = false

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()

    @IBAction func deleteAllButtonTouched(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: NSLocalizedString("Delete All Locations", comment: "title of 'Delete All' UIAlertController"),
                                      message: NSLocalizedString("All of your saved parking locations will be deleted!", comment: "message of 'Delete All' UIAlertController"), preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete All", comment: "Delete All"), style: .destructive) { (action) in
            for parkingLocation in self.parkingLocations {
                self.managedObjectContext.delete(parkingLocation)
            }
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Failed to delete locations in Core Data: \(error)")
            }
            self.parkingLocations = [ParkingLocation]()
            self.updateUI()
            self.tableView.reloadData()
        }
        alert.addAction(deleteAction)
        let cancelAction = UIAlertAction(title: LocalizedString.cancelMessage, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func parkButtonTouched(_ sender: UIButton) {
        let status = CLLocationManager.authorizationStatus()
        if status == .denied || status == .restricted || !CLLocationManager.locationServicesEnabled() {
            showLocationAuthorizationDeniedAlert()
            return
        }
        // If isLocating is true, tap this button again to stop locating
        if isLocating {
            stopLocationManager()
        } else {
            startLocationManager()
        }
    }
    
    func showLocationAuthorizationDeniedAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Location Services Disabled", comment: "title of 'Location Disabled' UIAlertController"),
                                      message: NSLocalizedString("Please enable location services for this app in Settings", comment: "message of 'Location Disabled' UIAlertController"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: LocalizedString.okMessage, style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func startLocationManager() {
        print(#function)
        isLocating = true
        updateUI()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationManager() {
        print(#function)
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil

        isLocating = false
        updateUI()
    }
    
    func insertNewLocationIntoTable(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil, let p = placemarks, !p.isEmpty {
                self.placemark = p.last!
            } else {
                self.placemark = nil
                print("Cannot reverse geocode this location")
            }
            let newParkingLocation = ParkingLocation(context: self.managedObjectContext)
            newParkingLocation.date = Date()
            newParkingLocation.location = location
            newParkingLocation.placemark = self.placemark
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Failed to save location information to Core Data: \(error)")
            }

            self.parkingLocations.insert(newParkingLocation, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.updateUI()
            
            let hudView = HudView.hud(inView: self.view, animated: true)
            hudView.text = NSLocalizedString("Done!", comment: "Done!")
        }
    }
    
    func updateUI() {
        if isLocating {
            parkButton.setTitle(NSLocalizedString("Stop", comment: "Stop"), for: .normal)
            parkButtonInstructionLabel.text = NSLocalizedString("Tap to stop locating...", comment: "Tap to stop locating...")
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            parkButtonInstructionLabel.text = NSLocalizedString("Tap here to park your car", comment: "Tap here to park your car")
            parkButton.setTitle(NSLocalizedString("Park Car", comment: "Park Car"), for: .normal)
        }
        
        if parkingLocations.isEmpty {
            instructionLabel.text = NSLocalizedString("Tap 'Park Car' to save your current location", comment: "Tap 'Park Car' to save your current location")
            deleteAllButton.isEnabled = false
        } else {
            instructionLabel.text = NSLocalizedString("Tap one parking location ⬇︎ to find your car", comment: "Tap one parking location ⬇︎ to find your car")
            deleteAllButton.isEnabled = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted || !CLLocationManager.locationServicesEnabled() {
            showLocationAuthorizationDeniedAlert()
        }

        let fetchRequest = NSFetchRequest<ParkingLocation>()
        let entity = ParkingLocation.entity()
        fetchRequest.entity = entity
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            parkingLocations = try managedObjectContext.fetch(fetchRequest)
        } catch {
            fatalError("Falied to load location information from Core Data: \(error)")
        }

        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.rowHeight = 65
        updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowNavigation" {
            if isLocating {
                stopLocationManager()
            }
            let indexPath = sender as! IndexPath
            let vc = segue.destination as! NavigationViewController
            vc.locationManager = locationManager
            vc.parkingLocation = parkingLocations[indexPath.row]
            vc.geocoder = geocoder
        }
    }

}

extension LocationListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parkingLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        
        let parkingLocation = parkingLocations[indexPath.row]
        let dateString = dateFormatter.string(from: parkingLocation.date)
        let addressString = Utils.generateAddressString(fromPlacemark: parkingLocation.placemark)

        cell.textLabel?.text = dateString
        cell.detailTextLabel?.text = addressString
        
        return cell
    }
}

extension LocationListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: NSLocalizedString("Delete This Location", comment: "title of 'Delete Location' UIAlertController"),
                                          message: NSLocalizedString("This parking location will be deleted!", comment: "message of 'Delete Location' UIAlertController"), preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: LocalizedString.deleteMessage, style: .destructive) { (action) in
                let parkingLocation = self.parkingLocations[indexPath.row]
                self.managedObjectContext.delete(parkingLocation)
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Failed to delete a location from Core Data: \(error)")
                }
                self.parkingLocations.remove(at: indexPath.row)
                self.updateUI()
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            alert.addAction(deleteAction)
            let cancelAction = UIAlertAction(title: LocalizedString.cancelMessage, style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowNavigation", sender: indexPath)
    }
}

extension LocationListViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("accuracy = \(newLocation.horizontalAccuracy)")
        // If newLocation is cached too long ago, discard it
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        // If newLocation.horizontalAccuracy is better than current saved one, use the new one
        if currentLocation == nil || newLocation.horizontalAccuracy < currentLocation!.horizontalAccuracy {
            currentLocation = newLocation
          
        /*
         * When should we say the current location is accurate enough and we can stop locationManager?
         *
         * The current strategy is:
         *   1. The horizontalAccuracy is within 20 meters, and
         *   2. The horizontalAccuracy difference between new and current saved one is less than 5 meters
         *
         * When GPS signal is weak, this condition may not be satisfied. For now, just leave it as it is
         */
        } else if newLocation.horizontalAccuracy <= 20.0, let currentLocation = currentLocation {
            if abs(newLocation.horizontalAccuracy - currentLocation.horizontalAccuracy) <= 5.0 {
                let adjustedLocation = Utils.transformLocation(fromLocation: newLocation)
                stopLocationManager()
                insertNewLocationIntoTable(adjustedLocation)
            }
        }
        /*
         * The following is for testing when GPS signal is weak, e.g. in a building
         */
        /*
        } else if newLocation.horizontalAccuracy <= 100.0 {
                let adjustedLocation = Utils.transformLocation(fromLocation: newLocation)
                stopLocationManager()
                insertNewLocationIntoTable(adjustedLocation)
        }
        */
    }
}

extension LocationListViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
