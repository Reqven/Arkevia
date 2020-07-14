//
//  Directory+CoreDataProperties.swift
//  Arkevia
//
//  Created by Reqven on 09/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//
//

import Foundation
import CoreData


extension Directory {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Directory> {
        return NSFetchRequest<Directory>(entityName: "Directory")
    }

    @NSManaged public var name: String
    @NSManaged public var path: String
    @NSManaged public var date: String?
    @NSManaged public var type: String?
    @NSManaged public var size: String?
    @NSManaged public var rel: String?
    @NSManaged public var mime: String?
    @NSManaged public var i18n: Bool
  
    @NSManaged public var userStorage: String?
    @NSManaged public var percentUseStorage: String?
    @NSManaged public var maxUserStorage: String?
  
    @NSManaged public var rm: Bool
    @NSManaged public var read: Bool
    @NSManaged public var write: Bool
    @NSManaged public var rename: Bool
    
    @NSManaged public var parent: Directory?
    @NSManaged public var directories: Set<Directory>
    @NSManaged public var files: Set<File>

}

// MARK: Generated accessors for directories
extension Directory {

    @objc(addDirectoriesObject:)
    @NSManaged public func addToDirectories(_ value: Directory)

    @objc(removeDirectoriesObject:)
    @NSManaged public func removeFromDirectories(_ value: Directory)

    @objc(addDirectories:)
    @NSManaged public func addToDirectories(_ values: NSSet)

    @objc(removeDirectories:)
    @NSManaged public func removeFromDirectories(_ values: NSSet)

}

// MARK: Generated accessors for files
extension Directory {

    @objc(addFilesObject:)
    @NSManaged public func addToFiles(_ value: File)

    @objc(removeFilesObject:)
    @NSManaged public func removeFromFiles(_ value: File)

    @objc(addFiles:)
    @NSManaged public func addToFiles(_ values: NSSet)

    @objc(removeFiles:)
    @NSManaged public func removeFromFiles(_ values: NSSet)

}
