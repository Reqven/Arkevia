//
//  ViewController.swift
//  Arkevia
//
//  Created by Reqven on 07/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit
import CoreData

class FileBrowserViewController: UIViewController {
    
    // MARK: - Properties
    var path: String?
    var name: String?
    var tableView: UITableView!
    var documentInteractionController: UIDocumentInteractionController!
    
    private lazy var dataProvider = DirectoryProvider()
    private lazy var spinner = UIActivityIndicatorView(style: .medium)
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Directory> = {
        let controller = dataProvider.createFetchedResultsController()
        let predicate = NSPredicate(format: "path == %@", path ?? DirectoryProvider.rootPath)
        controller.fetchRequest.predicate = predicate
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return controller
    }()
    
    private var directory: Directory? {
        return fetchedResultsController.fetchedObjects?.first
    }

    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        load()
    }
    
    @objc func load() {
        spinner.startAnimating()
        dataProvider.fetchDirectory(for: self.path) { error in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.handleFetchOperationCompletion(error: error)
            }
        }
    }
    
    @objc func upload(file: URL, to path: String) {
        spinner.startAnimating()
        NetworkManager.shared.upload(file: file, to: path) { result in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                if case .failure(let error) = result {
                    self.handleUploadOperationCompletion(error: error)
                } else {
                    self.handleUploadOperationCompletion(error: nil)
                }
            }
        }
    }
    
    @objc func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
}



// MARK: - Setup
extension FileBrowserViewController {
    
    private func initialSetup() {
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.pinToEdges(of: view)
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = name ?? DirectoryProvider.rootName
        
        spinner.hidesWhenStopped = true
        spinner.color = .gray
        
        let barButton = UIBarButtonItem(customView: spinner)
        let uploadButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(presentDocumentPicker))
        //self.navigationItem.setRightBarButton(barButton, animated: true)
        //self.navigationItem.setLeftBarButton(uploadButton, animated: true)
        self.navigationItem.setRightBarButtonItems([barButton, uploadButton], animated: true)

        setupSearchBar()
    }
    
    private func setupSearchBar() {
        let searchController = UISearchController()
        searchController.obscuresBackgroundDuringPresentation  = false
        navigationItem.searchController                        = searchController
        
        // TODO: Implement search
        // searchController.searchResultsUpdater = self
    }
}



// MARK: - UITableViewDataSource
extension FileBrowserViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let directory = directory else { return 0 }
        return directory.directories.count + directory.files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //TODO: Refactor
        guard let directory = directory else { return cell }
        let directories = directory.directoriesArray.sorted { $0.name < $1.name }
        let files = directory.filesArray.sorted { $0.name < $1.name }
        
        switch indexPath.row {
            case let index where index < directories.count:
                let item = directories[indexPath.row]
                cell.textLabel?.text = item.name
                cell.accessoryType = .disclosureIndicator
                
                if case "recyclebin" = item.type {
                    cell.imageView?.image = UIImage(systemName: "trash.fill")
                } else {
                    cell.imageView?.image = UIImage(systemName: "folder.fill")
                }
            
            default:
                let item = files[indexPath.row - directories.count]
                cell.textLabel?.text = item.fileName
                cell.detailTextLabel?.text = item.date
                cell.imageView?.image = UIImage(systemName: "doc.text.fill")
        }
        return cell
    }
}



// MARK: - UITableViewDelegate
extension FileBrowserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //TODO: Refactor
        guard let directory = directory else { return }
        let directories = directory.directoriesArray.sorted { $0.name < $1.name }
        let files = directory.filesArray.sorted { $0.name < $1.name }
        
        switch indexPath.row {
            case let index where index < directories.count:
                let item = directories[indexPath.row]
                let controller = FileBrowserViewController()
                controller.path = item.path
                controller.name = item.name
            
                navigationController?.pushViewController(controller, animated: true)
            
            default:
                let file = files[indexPath.row - directories.count]
                download(file)
        }
    }
}



// MARK: - NSFetchedResultsControllerDelegate
extension FileBrowserViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
    
    private func handleFetchOperationCompletion(error: Error?) {
        if let error = error {
            print(error)
            
            let alert = UIAlertController(
                title: "Fetch failed",
                message: "An error occured while trying to fetch the content for this directory.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            resetAndRefetch()
            tableView.reloadData()
        }
    }
    
    private func handleUploadOperationCompletion(error: Error?) {
        if let error = error {
            print(error)
            
            let alert = UIAlertController(
                title: "Upload failed",
                message: "An error occured while trying to upload your file to the server.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            load()
        }
    }
    
    private func resetAndRefetch() {
        dataProvider.persistentContainer.viewContext.reset()
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }
}



// MARK: - URLSessionDownloadDelegate
extension FileBrowserViewController:  URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("\(url.lastPathComponent).pdf")
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            preview(destinationURL)
        } catch let error {
            print("Copy Error: \(error.localizedDescription)")
        }
    }
    
    private func downloadURL(for file: File) -> URL? {
        let queryItems = [URLQueryItem(name: "currentFolder", value: file.path), URLQueryItem(name: "target", value: file.id)]
        var urlComponents = URLComponents(string: "https://www.arkevia.com/safe-secured/browser/openFile.action")!
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
    }
    
    private func download(_ file: File) {
        guard let url = downloadURL(for: file) else { return }
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
}



// MARK: - UIDocumentInteractionControllerDelegate
extension FileBrowserViewController: UIDocumentInteractionControllerDelegate {
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    private func preview(_ url: URL) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = self
        DispatchQueue.main.async {
            self.documentInteractionController.presentPreview(animated: true)
        }
    }
}



// MARK: - UIDocumentPickerDelegate
extension FileBrowserViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let path = path, let url = urls.first else { return }
        
        let fileName = url.deletingPathExtension().lastPathComponent
        let mimeType = FileHelper.mimeTypeForPath(path: url.path)
        
        guard let directory = directory else { return }
        guard !directory.files.contains(where: { fileName == $0.name && mimeType == $0.mime }) else {
            let alert = UIAlertController(
                title: "File already exists",
                message: "Replacing existing files is not supported yet.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        upload(file: url, to: path)
    }
}


