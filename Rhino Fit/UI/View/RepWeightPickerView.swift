//
//  RepWeightPicker.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.04.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

@IBDesignable class RepWeightPickerView: UIStackView {
    var delegate: RepWeightPickerDelegate?
    
    var pickerView: UIPickerView!
    var button: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    private func initSubviews() {
        self.axis = .vertical

        pickerView = UIPickerView()
        pickerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical) // so the button has higher priority
        pickerView.delegate = self
        pickerView.dataSource = self
        addArrangedSubview(pickerView)

        button = UIButton(type: .system)
        button.setTitle("Ok", for: .normal)
        button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        addArrangedSubview(button)
    }
    
    @objc
    private func buttonClicked() {
        delegate?.repWeightPickerViewButtonClicked(self)
    }
    
    func select(weight: Float, animated: Bool) {
        let integer = Int(weight.rounded(.down))
        let comma = Int((weight*100).rounded(.down)) % 100
        
        var first = integer
        var second = 0
        switch comma {
        case 0..<13:
            break
        case 13..<38:
            second = 1
        case 38..<68:
            second = 2
        case 68..<88:
            second = 3
        default:
            first += 1
        }
        pickerView.selectRow(first, inComponent: 1, animated: animated)
        pickerView.selectRow(second, inComponent: 2, animated: animated)
    }
    
    func select(repetitions: Int, animated: Bool) {
        pickerView.selectRow(repetitions - 1, inComponent: 0, animated: animated)
    }
}

protocol RepWeightPickerDelegate {
    func repWeightPickerView(_ repWeightPickerView: RepWeightPickerView, didSelect repetitions: Int)
    
    func repWeightPickerView(_ repWeightPickerView: RepWeightPickerView, didSelect weight: Float)
    
    func repWeightPickerViewButtonClicked(_ repWeightPickerView: RepWeightPickerView)
}

extension RepWeightPickerView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            delegate?.repWeightPickerView(self, didSelect: repetitionsFor(row: row))
        case 1:
            delegate?.repWeightPickerView(self, didSelect: weightFor(first: row, second: pickerView.selectedRow(inComponent: 2)))
        case 2:
            delegate?.repWeightPickerView(self, didSelect: weightFor(first: pickerView.selectedRow(inComponent: 1), second: row))
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel
        if view == nil {
            label = UILabel()
        } else {
            label = view as! UILabel
        }
        label.text = titleFor(row: row, component: component)
        label.font = UIFont.systemFont(ofSize: 21)
        switch component {
        case 0:
            label.textAlignment = NSTextAlignment.right
        case 1:
            label.textAlignment = NSTextAlignment.right
        case 2:
            label.textAlignment = NSTextAlignment.left
        default:
            break
        }
        return label
    }
    
    private func titleFor(row: Int, component: Int) -> String? {
        switch component {
        case 0:
            return "\(String(row + 1)) x"
        case 1:
            return String(row)
        case 2:
            return ".\(String(row * 25)) kg"
        default:
            return nil
        }
    }
    
    private func weightFor(first: Int, second: Int) -> Float {
        return Float(first) + Float(second)*0.25
    }
    
    private func repetitionsFor(row: Int) -> Int {
        return row + 1
    }
}

extension RepWeightPickerView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 2998
        case 1:
            return 2999
        case 2:
            return 4
        default:
            return 0
        }
    }
}
