//
//  DatePickerTableViewCell.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 03.05.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class DatePickerTableViewCell: UITableViewCell {
    var delegate: DatePickerTableViewCellDelegate?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func awakeFromNib() {
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }
    
    @objc
    private func dateChanged(_ sender: UIDatePicker) {
        delegate?.dateChanged(date: sender.date)
    }
}

protocol DatePickerTableViewCellDelegate {
    func dateChanged(date: Date)
}
