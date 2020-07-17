//
//  FileHelper.swift
//  Arkevia
//
//  Created by DevAndDeploy on 14/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import Foundation
import MobileCoreServices

enum FileHelper {
    
    static func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
    static func extensionForMimeType(mime: String) -> String? {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil)?.takeRetainedValue()
        let fileExtension = UTTypeCopyPreferredTagWithClass((unmanagedFileUTI)!, kUTTagClassFilenameExtension)?.takeRetainedValue()
        
        guard let value = fileExtension else { return nil }
        return value as String
    }
    
    static func safeFileName(of fileName: String) -> String {
        var illegalCharacters = CharacterSet(charactersIn: ":/")
        illegalCharacters.formUnion(.newlines)
        illegalCharacters.formUnion(.illegalCharacters)
        illegalCharacters.formUnion(.controlCharacters)

        return fileName.components(separatedBy: illegalCharacters).joined(separator: "")
    }
}

