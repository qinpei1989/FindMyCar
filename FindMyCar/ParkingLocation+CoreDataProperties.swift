//
//  ParkingLocation+CoreDataProperties.swift
//  FindMyCar
//
//  Created by Pei Qin on 4/8/17.
//  Copyright © 2017 Pei Qin. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData


extension ParkingLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ParkingLocation> {
        return NSFetchRequest<ParkingLocation>(entityName: "ParkingLocation")
    }

    @NSManaged public var location: CLLocation
    @NSManaged public var date: Date
    @NSManaged public var placemark: CLPlacemark?

}
