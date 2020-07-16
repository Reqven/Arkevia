//
//  DirectoryCell.swift
//  Arkevia
//
//  Created by DevAndDeploy on 16/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit

class DirectoryCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        accessoryType = .disclosureIndicator
    }
}

// MARK: - Setup
extension DirectoryCell {

    func setup(with directory: Directory) {
        textLabel?.text = directory.name
        if case "recyclebin" = directory.type {
            imageView?.image = UIImage(systemName: "trash.fill")
        } else {
            imageView?.image = UIImage(systemName: "folder.fill")
        }
        
        setNeedsLayout()
    }
}
