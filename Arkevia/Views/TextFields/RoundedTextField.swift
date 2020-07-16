//
//  RoundedTextField.swift
//  Arkevia
//
//  Created by Reqven on 13/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {
    
    var textPadding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        minimumFontSize = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.1
        layer.shadowOffset.height = -3
        backgroundColor = .tertiarySystemBackground
        autocorrectionType = .no
        clearButtonMode = .whileEditing
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}

