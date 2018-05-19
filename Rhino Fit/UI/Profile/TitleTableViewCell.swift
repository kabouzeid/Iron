//
//  TitleTableViewCell.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 19.05.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    var delegate: TitleTableViewCellDelegate?

    @IBOutlet weak var titleTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
extension TitleTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        var title = textField.text
        title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        if title?.isEmpty ?? true {
            title = nil
        }
        textField.text = title
        delegate?.titleChanged(title: title)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
protocol TitleTableViewCellDelegate {
    func titleChanged(title: String?)
}

