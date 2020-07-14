//
//  DirectoryProvider.swift
//  Arkevia
//
//  Created by Reqven on 10/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import Foundation
import CoreData

class DirectoryProvider {

    static let rootName = "MySafe"
    static let rootPath = "/MySafe/"
    private let openAction = "https://www.arkevia.com/safe-secured/browser/open.action"
    private let openFolderAction = "https://www.arkevia.com/safe-secured/browser/openFolder.action"
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Arkevia")
        container.loadPersistentStores { storeDesription, error in
            guard error == nil else {
                fatalError("Unresolved error \(error!)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.undoManager = nil
        return container
    }()
    
    
    func createFetchedResultsController() -> NSFetchedResultsController<Directory> {
        let fetchRequest = Directory.createFetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }
    
    
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        return taskContext
    }
    
    
    private func decode(from data: Data, with context: NSManagedObjectContext) throws -> Directory {
        let decoder = JSONDecoder()
        let codingUserInfoKey = CodingUserInfoKey(rawValue: "context")!
        decoder.userInfo[codingUserInfoKey] = context
        
        // print(String(decoding: data, as: UTF8.self))
        
        let root = try decoder.decode(Root.self, from: data)
        let directory = root.cwd
        
        if let _ = root.tree {
            directory.name = DirectoryProvider.rootName
            directory.path = DirectoryProvider.rootPath
        }
        if let notIn = fetchNotIn(directory: directory, context: context) {
            context.delete(objects: notIn)
        }
        if let cached = fetchPersisted(path: directory.path, context: context) {
            if let parent = cached.parent {
                directory.parent = parent
            }
        }
        return directory
    }
    
    
    private func fetchPersisted(path: String, context: NSManagedObjectContext) -> Directory? {
        let request = Directory.createFetchRequest()
        request.predicate = NSPredicate(format: "path == %@", path)
        request.includesPendingChanges = false
        
        guard let results = try? context.fetch(request) else { return nil }
        guard let item = results.first else { return nil }
        return item
    }
    
    
    private func fetchNotIn(directory: Directory, context: NSManagedObjectContext) -> [Directory]? {
        let request = Directory.createFetchRequest()
        request.predicate = NSPredicate(format: "parent.path == %@", directory.path)
        request.includesPendingChanges = false
        
        guard let results = try? context.fetch(request) else { return nil }
        return results.filter { (dir) -> Bool in
            return !directory.directoriesArray.contains(where: { dir.path == $0.path })
        }
    }
    
    
    func fetchDirectory(for path: String? = nil, completionHandler: @escaping (Error?) -> Void) {
        
        let queryItems = [
            URLQueryItem(name: "target", value: path ?? DirectoryProvider.rootPath),
            URLQueryItem(name: "sortName", value: "name"),
            URLQueryItem(name: "sortType", value: "asc"),
        ]
        let endpoint = path == nil ? openAction : openFolderAction
        var urlComponents = URLComponents(string: endpoint)!
        urlComponents.queryItems = queryItems
    
        let taskContext = newTaskContext()
        
        NetworkManager.shared.loadUser { result in
            switch(result) {
                case .failure(let error):
                    completionHandler(error)
                case .success(_):
                    
                    let session = URLSession(configuration: .default)
                    let task = session.dataTask(with: urlComponents.url!) { data, _, urlSessionError in
                        
                        guard urlSessionError == nil else {
                            completionHandler(urlSessionError)
                            return
                        }
                        guard let data = data else {
                            completionHandler(NSError(domain: "Network Unavailable", code: 0))
                            return
                        }
                        
                        taskContext.performAndWait {
                            do {
                                let _ = try self.decode(from: data, with: taskContext)
                            } catch {
                                completionHandler(error)
                                return
                            }
                            if taskContext.hasChanges {
                                do {
                                    try taskContext.save()
                                } catch {
                                    completionHandler(error)
                                    return
                                }
                                taskContext.reset()
                            }
                        }
                        completionHandler(nil)
                    }
                    task.resume()
            }
        }
    }
    

    func deleteAll(completionHandler: @escaping (Error?) -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Directory")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            
            // Execute the batch insert
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                batchDeleteResult.result != nil {
                completionHandler(nil)

            } else {
                completionHandler(NSError(domain: "batchDeleteError", code: 0))
            }
        }
    }
}
