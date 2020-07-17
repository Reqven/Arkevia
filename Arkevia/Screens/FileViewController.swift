//
//  FileViewController.swift
//  Arkevia
//
//  Created by DevAndDeploy on 17/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit
import QuickLook

class FileViewController: UIViewController {

    // MARK: - Properties
    var file: File!
    var localURL: URL?
    let spinner = UIActivityIndicatorView(style: .medium)
    
    
    // MARK: - Methods
    init(with file: File) {
        super.init(nibName: nil, bundle: nil)
        self.file = file
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        
        //TODO: Check if local file exists
        let queryItems = [URLQueryItem(name: "currentFolder", value: file.path), URLQueryItem(name: "target", value: file.id)]
        var urlComponents = URLComponents(string: "https://www.arkevia.com/safe-secured/browser/openFile.action")!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else { return }
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = urlSession.downloadTask(with: url)
        task.resume()
    }
}



// MARK: - Setup
extension FileViewController {
    
    private func initialSetup() {
        title = file.fileName
        view.backgroundColor = .systemBackground
        
        setupSpinner()
    }
    
    private func setupSpinner() {
        view.addSubview(spinner)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}



// MARK: - URLSessionDownloadDelegate
extension FileViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(file.idFileName)
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            localURL = destinationURL
            
            DispatchQueue.main.async {
                let previewController = QLPreviewController()
                previewController.modalPresentationStyle = .fullScreen
                previewController.dataSource = self
                
                self.present(previewController, animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        } catch let error {
            print("Copy Error: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let downloaded = (totalBytesWritten / file.size) * 100
        //TODO: Implement progress bar
    }
}



// MARK: - QLPreviewControllerDataSource
extension FileViewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return localURL == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let url = localURL else { fatalError("Could not load \(file.idFileName)") }
        return url as QLPreviewItem
    }
}
