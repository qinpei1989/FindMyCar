//
//  Utils.swift
//  FindMyCar
//
//  Created by Pei Qin on 08/08/2017.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import Foundation
import CoreLocation

class Utils {
    
    static let ee = 0.00669342162296594323
    static let a = 6378245.0
    
    /*
     * For locations in China, we need to do some extra work for CLLocation since China is using GCJ-02, a different
     * coordinate system from WGS-84, which is used by most countries
     */
    static func transformLocation(fromLocation location: CLLocation) -> CLLocation {
        let adjustedCoordinate = Utils.transformFromWGSToGCJ(locationCoordinate: location.coordinate)
        let adjustedLocation = CLLocation(coordinate: adjustedCoordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        return adjustedLocation
    }
    
    static func isLocationWithinChina(locationCoordinate coordinate: CLLocationCoordinate2D) -> Bool {
        if coordinate.longitude < 72.004 || coordinate.longitude > 137.8347 || coordinate.latitude < 0.8293 || coordinate.latitude > 55.8271 {
            return false
        } else {
            return true
        }
    }
    
    static func transformFromWGSToGCJ(locationCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        
        if isLocationWithinChina(locationCoordinate: coordinate) == false {
            return coordinate
        } else {
            var adjustedLatitude = transformLatitude(withX: coordinate.longitude - 105, withY: coordinate.latitude - 35)
            var adjustedLongitude = transformLongitude(withX: coordinate.longitude - 105, withY: coordinate.latitude - 35)
            let latitudeInRadians = coordinate.latitude / 180 * Double.pi
            
            var magic = sin(latitudeInRadians)
            magic = 1 - ee * magic * magic
            let sqrtMagic = sqrt(magic)
            adjustedLatitude = (adjustedLatitude * 180) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
            adjustedLongitude = (adjustedLongitude * 180) / (a / sqrtMagic * cos(latitudeInRadians) * Double.pi)
            let adjustedCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude + adjustedLatitude, longitude: coordinate.longitude + adjustedLongitude)
            return adjustedCoordinate
        }
    }
    
    static func transformLatitude(withX x: Double, withY y: Double) -> Double {
        var latitude = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        latitude += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        latitude += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
        latitude += (160.0 * sin(y / 12.0 * Double.pi) + 320.0 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
        return latitude
    }
    
    static func transformLongitude(withX x: Double, withY y: Double) -> Double {
        var longitude = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        longitude += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0;
        longitude += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0;
        longitude += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0;
        return longitude
    }
    
    /*
     * Construct an address string from CLPlacemark object.
     * For example:
     *       "1 Infinite Loop Cupertino"
     *       "林士街2号 香港"
     */
    static func generateAddressString(fromPlacemark placemark: CLPlacemark?) -> String {
        var addressString = ""
        if let address = placemark, let thoroughfare = address.thoroughfare {
            if let subThoroughfare = address.subThoroughfare {
                addressString += subThoroughfare + " "
            }
            
            if let countryCode = address.isoCountryCode {
                if countryCode == "CN" {
                    addressString = thoroughfare + addressString
                } else {
                    addressString += thoroughfare
                }
            }
        } else {
            addressString = NSLocalizedString("(Unknown Place)", comment: "(Unknown Place)")
        }
        
        if let address = placemark, let city = address.locality {
            addressString += " " + city
        }
        return addressString
    }

    
    /*
     * This method returns the bearing between two CLLocation objects. For example:
     *
     *                       ^N
     *                       |
     *                       |   x  <- p2
     *                       |
     *           ------------+---------->E
     *                       |
     *              p1-> x   |
     *
     *   getBearingBetweenTwoPoints(location1: p1, location2: p2)  returns  1/4*pi, i.e. 45 degrees
     *   getBearingBetweenTwoPoints(location1: p2, location2: p1)  returns -3/4*pi, i.e. -135 degrees
     */
    static func getBearingBetweenTwoPoints(location1: CLLocation, location2: CLLocation) -> Double {
        let lat1 = degreesToRadians(degrees: location1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: location1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: location2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: location2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    static func degreesToRadians(degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    static func radiansToDegrees(radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
}
