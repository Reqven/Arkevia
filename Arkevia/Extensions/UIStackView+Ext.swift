//
//  UIStackView+Ext.swift
//  Arkevia
//
//  Created by Reqven on 13/07/2020.
//  Copyright © 2020 Manu Marchand. All rights reserved.
//

import UIKit

extension UIStackView {
    
    func addArrangedSubviews(_ views: UIView...) {
        for view in views { addArrangedSubview(view) }
    }
}

