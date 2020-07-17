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
    
    @objc func emptyBin() {
        spinner.startAnimating()
        dataProvider.emptyBin { error in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.handleUploadOperationCompletion(error: error)
            }
        }
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
        tableView.register(FileCell.self, forCellReuseIdentifier: "FileCell")
        tableView.register(DirectoryCell.self, forCellReuseIdentifier: "DirectoryCell")
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.pinToEdges(of: view)
    }
    
    private func setupNavigationBar() {
        title = name ?? DirectoryProvider.rootName
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = name == nil ? .always : .never

        spinner.hidesWhenStopped = true
        spinner.color = .gray
        
        let spinnerButton = UIBarButtonItem(customView: spinner)
        let uploadButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(presentDocumentPicker))
        let emptyBinButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(emptyBin))
        
        var barButtons = [spinnerButton]
        if let path = path, path == "/MySafe/MyRecycleBin/" {
            barButtons.append(emptyBinButton)
        } else {
            barButtons.append(uploadButton)
        }
        navigationItem.rightBarButtonItems = barButtons.reversed()
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
        
        //TODO: Refactor
        guard let directory = directory else { return UITableViewCell() }
        let directories = directory.directoriesArray.sorted { $0.name < $1.name }
        let files = directory.filesArray.sorted { $0.name < $1.name }
        
        switch indexPath.row {
            case let index where index < directories.count:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "DirectoryCell", for: indexPath) as? DirectoryCell {
                    cell.setup(with: directories[indexPath.row])
                    return cell
                }
            
            default:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as? FileCell {
                    cell.setup(with: files[indexPath.row - directories.count])
                    return cell
                }
        }
        return UITableViewCell()
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        guard let directory = directory else { return nil }
        
        let directories = directory.directoriesArray.sorted { $0.name < $1.name }
        let files = directory.filesArray.sorted { $0.name < $1.name }
        
        switch indexPath.row {
            case let index where index < directories.count:
                return nil
            
            default:
                let file = files[indexPath.row - directories.count]
                let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
                    
                    self.spinner.startAnimating()
                    self.dataProvider.delete(files: [file]) { error in
                        
                        DispatchQueue.main.async {
                            self.spinner.stopAnimating()
                            
                            if let error = error {
                                completion(false)
                                print(error)
                                
                                let alert = UIAlertController(
                                    title: "Delete failed",
                                    message: "An error occured while trying to delete this file.",
                                    preferredStyle: .alert
                                )
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                completion(true)
                                self.load()
                            }
                        }
                    }
                }
                deleteAction.image = UIImage(named: "delete-icon")
                return UISwipeActionsConfiguration(actions: [deleteAction])
                
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



// MARK: - FileDownload
extension FileBrowserViewController {
    
    private func downloadURL(for file: File) -> URL? {
        let queryItems = [URLQueryItem(name: "currentFolder", value: file.path), URLQueryItem(name: "target", value: file.id)]
        var urlComponents = URLComponents(string: "https://www.arkevia.com/safe-secured/browser/openFile.action")!
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
    }
    
    private func download(_ file: File) {
        guard let url = downloadURL(for: file) else { return }
    
        let downloadTask = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location else { return }
            
            let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(file.idFileName)
            try? FileManager.default.removeItem(at: destinationURL)
            
            do {
                try FileManager.default.copyItem(at: location, to: destinationURL)
                self.preview(destinationURL)
            } catch let error {
                print("Copy Error: \(error.localizedDescription)")
            }
        }
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


