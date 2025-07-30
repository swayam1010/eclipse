//
//  CachedBook+CoreDataProperties.swift
//  Eclipse
//
//  Created by user@87 on 20/02/25.
//
//

import Foundation
import CoreData


extension CachedBook {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedBook> {
        return NSFetchRequest<CachedBook>(entityName: "CachedBook")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var authors: String?
    @NSManaged public var bookDescription: String?
    @NSManaged public var averageRating: Double
    @NSManaged public var imageURL: String?
    @NSManaged public var previewLink: String?
    @NSManaged public var pageCount: Int64
    @NSManaged public var query: String?
    @NSManaged public var ratingsCount: Int64

}

extension CachedBook : Identifiable {

}
