//
//  File+CoreDataClass.swift
//  Arkevia
//
//  Created by Reqven on 09/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//
//

import Foundation
import CoreData

@objc(File)
public class File: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case keywords
        case rm
        case rename
        case foldername
        case date
        case size
        case basepath
        case sender
        case share
        case name
        case write
        case path
        case id = "techid"
        case read
        case mime
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError("Codable not implemented")
        //var container = encoder.container(keyedBy: CodingKeys.self)
        //try container.encode(rm ?? "rm", forKey: .rm)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        guard let codingUserInfoKeyContext = CodingUserInfoKey.context else { fatalError() }
        guard let context = decoder.userInfo[codingUserInfoKeyContext] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "File", in: context) else { fatalError() }
        
        do {
            self.init(entity: entity, insertInto: context)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.keywords   = try container.decode(String.self, forKey: .keywords)
            self.rm         = try container.decode(Bool.self, forKey: .rm)
            self.rename     = try container.decode(Bool.self, forKey: .rename)
            self.foldername = try container.decode(String.self, forKey: .foldername)
            self.date       = try container.decode(String.self, forKey: .date)
            self.size       = try container.decode(Int64.self, forKey: .size)
            self.basepath   = try container.decode(String.self, forKey: .basepath)
            self.sender     = try container.decodeIfPresent(String.self, forKey: .sender)
            self.share      = try container.decode(Bool.self, forKey: .share)
            self.name       = try container.decode(String.self, forKey: .name)
            self.write      = try container.decode(Bool.self, forKey: .write)
            self.path       = try container.decode(String.self, forKey: .path)
            self.id         = try container.decode(String.self, forKey: .id)
            self.read       = try container.decode(Bool.self, forKey: .read)
            self.mime       = try container.decode(String.self, forKey: .mime)
        } catch {
            context.delete(self)
            throw error
        }
        
    }
}

