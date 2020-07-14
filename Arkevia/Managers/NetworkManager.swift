//
//  NetworkManager.swift
//  Arkevia
//
//  Created by Reqven on 07/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit
import CoreData

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
}
