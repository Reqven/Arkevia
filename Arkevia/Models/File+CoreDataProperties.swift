//
//  File+CoreDataProperties.swift
//  Arkevia
//
//  Created by Reqven on 09/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//
//

import Foundation
import CoreData


extension File {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<File> {
        return NSFetchRequest<File>(entityName: "File")
    }

    @NSManaged public var basepath: String
    @NSManaged public var date: String
    @NSManaged public var foldername: String
    @NSManaged public var keywords: String
    @NSManaged public var mime: String
    @NSManaged public var name: String
    @NSManaged public var path: String
    @NSManaged public var read: Bool
    @NSManaged public var rename: Bool
    @NSManaged public var rm: Bool
    @NSManaged public var sender: String?
    @NSManaged public var share: Bool
    @NSManaged public var size: Int64
    @NSManaged public var id: String
    @NSManaged public var write: Bool
    
    @NSManaged public var directory: Directory?
    
}
