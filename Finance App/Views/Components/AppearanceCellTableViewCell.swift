//
//  AppearanceCellTableViewCell.swift
//  Finance App
//
//  Created by Jas  on 8/19/25.
//

import UIKit

class AppearanceCell: UITableViewCell {

    static let reuseIdentifier = "AppearanceCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // We use .value1 to get the standard cell layout for free
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configures the cell with a title and a system icon.
    func configure(title: String, iconName: String) {
        textLabel?.text = title
        
        // Create a symbol configuration for a nice, bold icon
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        imageView?.image = UIImage(systemName: iconName, withConfiguration: config)
        
        // Use adaptive system colors for the icon
        imageView?.tintColor = .label
    }
}

