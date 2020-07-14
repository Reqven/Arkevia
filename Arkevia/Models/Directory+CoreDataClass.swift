//
//  Directory+CoreDataClass.swift
//  Arkevia
//
//  Created by Reqven on 09/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Directory)
public class Directory: NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case path = "techid"
        case date
        case type
        case size
        case rel
        case mime
        case i18n
        case userStorage
        case percentUseStorage
        case maxUserStorage
        case rm
        case read
        case write
        case rename
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError("Codable not implemented")
        //var container = encoder.container(keyedBy: CodingKeys.self)
        //try container.encode(rm ?? "rm", forKey: .rm)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let codingUserInfoKeyContext = CodingUserInfoKey.context else { fatalError() }
        guard let context = decoder.userInfo[codingUserInfoKeyContext] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "Directory", in: context) else { fatalError() }

        do {
            self.init(entity: entity, insertInto: context)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name              = try container.decode(String.self, forKey: .name)
            self.path              = try container.decode(String.self, forKey: .path)
            self.date              = try container.decodeIfPresent(String.self, forKey: .date)
            self.type              = try container.decodeIfPresent(String.self, forKey: .type)
            self.size              = try container.decodeIfPresent(String.self, forKey: .size)
            self.rel               = try container.decodeIfPresent(String.self, forKey: .rel)
            self.mime              = try container.decodeIfPresent(String.self, forKey: .mime)
            self.i18n              = try container.decodeIfPresent(Bool.self, forKey: .i18n) ?? false
            
            self.userStorage       = try container.decodeIfPresent(String.self, forKey: .userStorage)
            self.percentUseStorage = try container.decodeIfPresent(String.self, forKey: .percentUseStorage)
            self.maxUserStorage    = try container.decodeIfPresent(String.self, forKey: .maxUserStorage)
            
            self.rm                = try container.decodeIfPresent(Bool.self, forKey: .rm) ?? false
            self.read              = try container.decodeIfPresent(Bool.self, forKey: .read) ?? false
            self.write             = try container.decodeIfPresent(Bool.self, forKey: .write) ?? false
            self.rename            = try container.decodeIfPresent(Bool.self, forKey: .rename) ?? false
            
            self.directories = NSSet()
            self.files = NSSet()
        } catch {
            context.delete(self)
            throw error
        }
    }
}

