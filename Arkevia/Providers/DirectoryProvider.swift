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
    private let deleteDefinitly = "https://www.arkevia.com/safe-secured/browser/deleteDefinitly.action"
    private let deleteTemporarilyAction = "https://www.arkevia.com/safe-secured/browser/deleteTemporarily.action"
    
    
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
        /*if let notIn = fetchNotIn(directory: directory, context: context) {
            context.delete(objects: notIn)
        }*/
        context.delete(objects: fetchNotIn(directory: directory, context: context))
        
        if let cached = fetchPersisted(path: directory.path, context: context) {
            directory.name = cached.name
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
    
    
    private func fetchNotIn(directory: Directory, context: NSManagedObjectContext) -> [NSManagedObject] {
        let directoryRequest = Directory.createFetchRequest()
        directoryRequest.predicate = NSPredicate(format: "parent.path == %@", directory.path)
        directoryRequest.includesPendingChanges = false
        
        let fileRequest = File.createFetchRequest()
        fileRequest.predicate = NSPredicate(format: "directory.path == %@", directory.path)
        fileRequest.includesPendingChanges = false
        
        var found = [NSManagedObject]()
        if let results = try? context.fetch(directoryRequest) {
            found.append(contentsOf: results.filter { dir -> Bool in
                return !directory.directoriesArray.contains(where: { dir.path == $0.path })
            })
        }
        if let results = try? context.fetch(fileRequest) {
            found.append(contentsOf: results.filter { file -> Bool in
                return !directory.filesArray.contains(where: { file.name == $0.name && file.mime == $0.mime })
            })
        }
        return found
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
    
    
    func delete(files: [File], completionHandler: @escaping (Error?) -> Void) {
        
        var queryItems = [
            URLQueryItem(name: "lastOperation", value: "openFolder"),
            URLQueryItem(name: "cmd", value: "deleteTemporarily")
        ]
        files.forEach { file in
            queryItems.append(contentsOf: [
                URLQueryItem(name: "currentFolders", value: file.path),
                URLQueryItem(name: "targets", value: file.id),
            ])
        }
        var urlComponents = URLComponents(string: deleteTemporarilyAction)!
        urlComponents.queryItems = queryItems
        print(urlComponents.url!)
        
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
                        guard !String(decoding: data, as: UTF8.self).contains("error") else {
                            completionHandler(NSError(domain: "Unknown error", code: 0))
                            return
                        }
                        completionHandler(nil)
                    }
                    task.resume()
            }
        }
    }
    
    
    func emptyBin(completionHandler: @escaping (Error?) -> Void) {
        
        NetworkManager.shared.loadUser { result in
            switch(result) {
                case .failure(let error):
                    completionHandler(error)
                case .success(_):
                    
                    let queryItems = [
                        URLQueryItem(name: "cmd", value: "deleteDefinitly"),
                        URLQueryItem(name: "target", value: "/MySafe/MyRecycleBin/")
                    ]
                    var urlComponents = URLComponents(string: self.deleteDefinitly)!
                    urlComponents.queryItems = queryItems
                    
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
                        
                        print(String(decoding: data, as: UTF8.self))
                        
                        guard !String(decoding: data, as: UTF8.self).contains("error") else {
                            completionHandler(NSError(domain: "Unknown error", code: 0))
                            return
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
