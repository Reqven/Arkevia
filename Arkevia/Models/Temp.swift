//
//  Temp.swift
//  Arkevia
//
//  Created by Reqven on 14/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import Foundation


// MARK: - Root
class Root: Decodable {
    let tree: Tree?
    let cdc: [DirectoryContent]
    let cwd: Directory
    let params: Params
    let disabled: [String]
    
    var directories = [Directory]()
    var files = [File]()
    
    enum CodingKeys: String, CodingKey {
        case tree, cdc, cwd, params, disabled, dirs
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tree          = try container.decodeIfPresent(Tree.self, forKey: .tree)
        cdc           = try container.decode([DirectoryContent].self, forKey: .cdc)
        cwd           = try container.decode(Directory.self, forKey: .cwd)
        params        = try container.decode(Params.self, forKey: .params)
        disabled      = try container.decode([String].self, forKey: .disabled)
    
        guard let _ = tree else {
            var contentContainer = try container.nestedUnkeyedContainer(forKey: .cdc)
            while !contentContainer.isAtEnd {
                if let file = try? contentContainer.decode(File.self) {
                    cwd.addToFiles(file)
                } else if let dir = try? contentContainer.decode(Directory.self) {
                    cwd.addToDirectories(dir)
                }
            }
            return
        }
        let treeContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .tree)
        cwd.directories = NSSet(array: try treeContainer.decode([Directory].self, forKey: .dirs))
    }
}


// MARK: - DirectoryContent
struct DirectoryContent: Codable {
    let keywords: String?
    let rm: Bool?
    let rename: Bool
    let foldername: String?
    let date: String
    let size: Int?
    let basepath: String?
    let sender: String?
    let share: Bool?
    let name: String
    let write: Bool
    let path: String?
    let techid: String
    let read: Bool
    let mime: String?
}


// MARK: - WorkingDirectory
struct WorkingDirectory: Codable {
    let rm: Bool
    let sorttype, sortname, percentUseStorage, date: String
    let type, size, userStorage: String
    let name: String
    let write: Bool?
    let techid: String
    let read: Bool?
    let writerestriction: CwdWriterestriction?
    let rel: String
    let mime, maxUserStorage: String
}


// MARK: - CwdWriterestriction
struct CwdWriterestriction: Codable {
    let movefile: Bool?
    let createfile: Bool?
}


// MARK: - Params
struct Params: Codable {
    let dotFiles: String
    let archives: [String]
    let uplMaxSize: String
    let extract: [String]
}


// MARK: - RootDirectory
struct RootDirectory: Codable {
    let rename: Bool?
    let name: String
    let write: Bool?
    let i18N: Bool?
    let writerestriction: CwdWriterestriction?
    let read: Bool?
    let techid, type: String
}


// MARK: - Tree
struct Tree: Codable {
    let name: String
    let writerestriction: TreeWriterestriction?
    let techid, type: String
    let dirs: [RootDirectory]
}


// MARK: - TreeWriterestriction
struct TreeWriterestriction: Codable {
    let movefolder, createfolder: Bool
}


// MARK: - BasicDirectory
struct BasicDirectory: Codable {
    let rm, rename: Bool
    let name: String
    let write, read: Bool
    let techid, mime, type, date: String
}

