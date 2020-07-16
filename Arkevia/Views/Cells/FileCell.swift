//
//  FileCell.swift
//  Arkevia
//
//  Created by DevAndDeploy on 16/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit

class FileCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
    }
}

// MARK: - Setup
extension FileCell {

    func setup(with file: File) {
        textLabel?.text = file.fileName
        detailTextLabel?.text = file.date
        imageView?.image = UIImage(systemName: "doc.text.fill")
        
        setNeedsLayout()
    }
}
