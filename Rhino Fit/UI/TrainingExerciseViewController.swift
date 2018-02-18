//
//  TrainingExerciseViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class TrainingExerciseViewController: UIViewController {
    
    var trainingExercise: TrainingExercise? {
        didSet {
            title = trainingExercise?.exercise?.title
            if tableView != nil {
                tableView.reloadData()
                selectCurrentSet()
            }
        }
    }
    
    private var currentSet: TrainingSet? {
        get {
            if let currentSet = trainingExercise?.trainingSets?.first(where: { (object) -> Bool in
                return !(object as! TrainingSet).isCompleted
            }) as? TrainingSet {
                return currentSet
            }
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.dataSource = self
        pickerView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self

        selectCurrentSet()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var completeSetButton: UIButton!
    @IBAction func completeSet(_ sender: UIButton) {
        if let selected = tableView.indexPathForSelectedRow {
            if self.trainingSet(of: selected) == currentSet {
                assert(currentSet!.repetitions > 0, "Tried to complete set with 0 repetitions")
                currentSet!.isCompleted = true
                tableView.reloadRows(at: [selected], with: .automatic)
            }
            selectCurrentSet()
        } else {
            // TODO go to next exercise or finish workout
            print("Go to next exercise or finish workout")
        }
    }
    @IBOutlet weak var stackView: UIStackView!
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func selectCurrentSet() {
        // then select the row of the current exercise
        if let set = currentSet, let row = trainingExercise?.trainingSets?.index(of: set) {
            let indexPath = IndexPath.init(row: row, section: 0)
            if set.repetitions == 0 {
                if row > 0 {
                    let previousSet = trainingExercise!.trainingSets![row - 1] as! TrainingSet
                    set.repetitions = previousSet.repetitions
                    set.weight = previousSet.weight
                } else {
                    // TODO set reps and weight to the most recent values from the past
                    set.repetitions = 1
                }
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            setPickerTo(trainingSet: set)
        } else {
            if let selected = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selected, animated: true)
            }
            setPickerTo(trainingSet: nil) // hides the picker
        }
    }
    
    private func setPickerTo(trainingSet: TrainingSet?) {
        guard trainingSet != nil else {
            if !isEditing {
                hidePickerView()
            }
            return
        }
        let weightRows = rowsFor(weight: trainingSet!.weight)
        pickerView.selectRow(rowFor(reps: Int(trainingSet!.repetitions)), inComponent: 0, animated: true)
        pickerView.selectRow(weightRows.0, inComponent: 1, animated: true)
        pickerView.selectRow(weightRows.1, inComponent: 2, animated: true)
        
        if !isEditing {
            showPickerView()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        
        // show/hide the whole stack view
        self.pickerView.alpha = editing ? 0 : 1
        self.completeSetButton.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.pickerView.isHidden = editing
            self.completeSetButton.isHidden = editing
            self.completeSetButton.alpha = editing ? 0 : 1
            self.stackView.layoutIfNeeded()
        }
        
        if !editing {
            selectCurrentSet()
        }
    }
    
    private func trainingSet(of indexPath: IndexPath) -> TrainingSet {
        return trainingExercise!.trainingSets![indexPath.row] as! TrainingSet
    }
    
    private func indexPath(of trainingSet: TrainingSet) -> IndexPath {
        return IndexPath(row: trainingExercise!.trainingSets!.index(of: trainingSet), section: 0)
    }
    
    private func hidePickerView() {
        self.pickerView.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.pickerView.isHidden = true
            self.stackView.layoutIfNeeded()
        })
    }
    
    private func showPickerView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.pickerView.isHidden = false
            self.stackView.layoutIfNeeded()
        }) { _ in
            self.pickerView.alpha = 1
        }
    }
}

extension TrainingExerciseViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // TODO add more sections for the other days
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return trainingExercise?.trainingSets?.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setCell", for: indexPath)
        let trainingSet = self.trainingSet(of: indexPath)

        if trainingSet.isCompleted || trainingSet == currentSet {
            let repetitions = trainingSet.repetitions
            cell.textLabel?.text = "\(repetitions) Repetition\(repetitions == 1 ? "" : "s") x \(trainingSet.weight) kg"
        } else {
            cell.textLabel?.text = "Set \(indexPath.row + 1)"
        }
        cell.detailTextLabel?.text = String(indexPath.row + 1)
        
        if trainingSet == currentSet {
            cell.textLabel?.textColor = UIColor.darkText
            cell.detailTextLabel?.textColor = UIColor.darkGray
        } else {
            cell.textLabel?.textColor = UIColor.lightGray
            cell.detailTextLabel?.textColor = UIColor.lightGray
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Today"
        // TODO other days
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trainingSet = self.trainingSet(of: indexPath)
            trainingExercise?.removeFromTrainingSets(trainingSet)
            tableView.reloadData()
            selectCurrentSet()
        }
    }
}

extension TrainingExerciseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let trainingSet = self.trainingSet(of: indexPath)
        return trainingSet.isCompleted || trainingSet == currentSet
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setPickerTo(trainingSet: self.trainingSet(of: indexPath))
    }
}

extension TrainingExerciseViewController: UIPickerViewDataSource {
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

extension TrainingExerciseViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let trainingExercise = self.trainingSet(of: indexPath)
            switch component {
            case 0:
                trainingExercise.repetitions = Int16(repetitionsFor(row: row))
            case 1:
                let second = rowsFor(weight: trainingExercise.weight).1
                trainingExercise.weight = weightFor(first: row, second: second)
            case 2:
                let first = rowsFor(weight: trainingExercise.weight).0
                trainingExercise.weight = weightFor(first: first, second: row)
            default:
                break
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
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
    
    private func rowFor(reps: Int) -> Int {
        return reps - 1
    }
    
    private func rowsFor(weight: Float) -> (Int, Int) {
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
        return(first, second)
    }
    
    private func weightFor(first: Int, second: Int) -> Float {
        return Float(first) + Float(second)*0.25
    }
    
    private func repetitionsFor(row: Int) -> Int {
        return row + 1
    }
}
