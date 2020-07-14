//
//  NSManagedObjectContext+Ext.swift
//  Arkevia
//
//  Created by Reqven on 14/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    func delete(objects: [NSManagedObject]) {
        objects.forEach({ self.delete($0) })
    }
}
