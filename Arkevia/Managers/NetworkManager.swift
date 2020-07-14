//
//  NetworkManager.swift
//  Arkevia
//
//  Created by Reqven on 07/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class NetworkManager {
    
    // MARK: - Properties
    static let shared = NetworkManager()
    private let cache = NSCache<NSString, UIImage>()
    private let cookieStorage = HTTPCookieStorage.shared
    
    private init() {}
}

// MARK: - Methods
extension NetworkManager {
    
    private func getTokenCookie(completed: @escaping (Result<Any, Error>) -> Void) {
        
        for cookie in cookieStorage.cookies! {
            cookieStorage.deleteCookie(cookie)
        }
        
        let url = URL(string: "https://www.arkevia.com/safe-secured/")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                completed(.failure(NSError(domain: "Task Error", code: 0)))
                return
            }
            if let _ = error {
                completed(.failure(NSError(domain: "Task Error", code: 0)))
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(NSError(domain: "Bad Response", code: 0)))
                return
            }
            guard let cookies = self.cookieStorage.cookies, cookies.contains(where: { $0.name == "JSESSIONID" }) else {
                completed(.failure(NSError(domain: "Cookie not retrieved", code: 0)))
                return
            }
            completed(.success(true))
        }
        task.resume()
    }
    
    
    func loadUser(completed: @escaping (Result<Any, Error>) -> Void) {
        
        let url = URL(string: "https://www.arkevia.com/safe-secured/loadUser.action")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                completed(.failure(NSError(domain: "Task Error", code: 0)))
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(NSError(domain: "Bad Response", code: 0)))
                return
            }
            completed(.success(true))
        }
        task.resume()
    }
    
    
    func login(username: String, password: String, completed: @escaping (Result<Any, Error>) -> Void) {
        
        getTokenCookie { result in
            switch(result) {
                case .failure(let error):
                    completed(.failure(error))
                case .success(_):
                    
                    let url = URL(string: "https://www.arkevia.com/j_spring_security_check")!
                    let postString = "j_username=\(username)&j_password=\(password)";
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = postString.data(using: String.Encoding.utf8);
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        if let _ = error {
                            completed(.failure(NSError(domain: "Task Error", code: 0)))
                            return
                        }
                        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                            completed(.failure(NSError(domain: "Bad Response", code: 0)))
                            return
                        }
                        completed(.success(true))
                    }
                    task.resume()
            }
        }
    }

    
    //TODO: Refactor
    func upload(path: String, fileUrl: URL, completed: @escaping (Result<Any, Error>) -> Void) {
        
        loadUser { result in
            switch(result) {
                case .failure(let error):
                    completed(.failure(error))
                case .success(_):
                    
                    guard let fileData = try? Data(contentsOf: fileUrl) else {
                        completed(.failure(NSError(domain: "Data", code: 0)))
                        return
                    }
                    var requestData = Data()
                    let boundary = UUID().uuidString
                    let fileName = fileUrl.lastPathComponent
                    let mimeType = self.mimeTypeForPath(path: fileUrl.path)
                    
                    let url = URL(string: "https://www.arkevia.com/safe-secured/browser/upload")!
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    
                    // Form-data content
                    requestData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    requestData.append("Content-Disposition: form-data; name=\"keywords\"\r\n\r\n".data(using: .utf8)!)
                    requestData.append("".data(using: .utf8)!)

                    requestData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    requestData.append("Content-Disposition: form-data; name=\"target\"\r\n\r\n".data(using: .utf8)!)
                    requestData.append(path.data(using: .utf8)!)

                    requestData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    requestData.append("Content-Disposition: form-data; name=\"upload\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                    requestData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                    requestData.append(fileData)
                    
                    requestData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

                    
                    let task = URLSession.shared.uploadTask(with: urlRequest, from: requestData, completionHandler: { data, response, error in
                        if let error = error {
                            completed(.failure(error))
                            return
                        }
                        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                            completed(.failure(NSError(domain: "Bad Response", code: 0)))
                            return
                        }
                        guard let data = data else {
                            completed(.failure(NSError(domain: "No response data", code: 0)))
                            return
                        }
                        guard !String(decoding: data, as: UTF8.self).contains("error") else {
                            completed(.failure(NSError(domain: "Unknown error", code: 0)))
                            return
                        }
                        completed(.success(true))
                    })
                    task.resume()
            }
        }
    }
    
    
    func downloadImage(from urlString: String, completed: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: urlString)
        if let image = cache.object(forKey: cacheKey) {
            completed(image)
            return
        }
        guard let url = URL(string: urlString) else {
            completed(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                error == nil,
                let response = response as? HTTPURLResponse, response.statusCode == 200,
                let data = data,
                let image = UIImage(data: data)
            else {
                completed(nil)
                return
            }
            self.cache.setObject(image, forKey: cacheKey)
            completed(image)
        }
        task.resume()
    }
    
    //TODO: Refactor and move out of this file
    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}
