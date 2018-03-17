//
//  CurrentTrainingExerciseViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class CurrentTrainingExerciseViewController: UIViewController {
    
    var trainingExercise: TrainingExercise? {
        didSet {
            title = trainingExercise?.exercise?.title
            if tableView != nil {
                tableView.reloadData()
                selectCurrentSet(animated: true)
            }
        }
    }
    
    var completeExerciseTitle: String? {
        didSet {
            if actionButton != nil && currentSet == nil {
                actionButton.setTitle(completeExerciseTitle ?? "Complete Exercise", for: .normal)
            }
        }
    }
    
    var delegate: TrainingExerciseViewControllerDelegate?
    
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
        
        selectCurrentSet(animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var actionButton: UIButton!
    @IBAction func performButtonAction(_ sender: UIButton) {
        if let selected = tableView.indexPathForSelectedRow {
            let selectedSet = trainingSet(of: selected)
            if selectedSet == currentSet {
                assert(selectedSet.repetitions > 0, "Tried to complete set with 0 repetitions")
                selectedSet.isCompleted = true
                tableView.reloadRows(at: [selected], with: .automatic)
                
                let training = trainingExercise!.training!
                if training.start == nil {
                    training.start = Date()
                }
                
                moveExerciseBehindLastCompleted(trainingExercise: selectedSet.trainingExercise!)
            }
            selectCurrentSet(animated: true)
        } else {
            delegate?.completeExercise(trainingExerciseViewController: self)
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

    private func moveExerciseBehindLastCompleted(trainingExercise: TrainingExercise) {
        let training = trainingExercise.training!
        let firstUncompleted = training.trainingExercises!.first(where: { (exercise) -> Bool in
            let exercise = exercise as! TrainingExercise
            return !exercise.isCompleted! && exercise != trainingExercise
        })
        if firstUncompleted != nil {
            let firstUncompleted = firstUncompleted! as! TrainingExercise
            let index = training.trainingExercises!.index(of: firstUncompleted)
            training.removeFromTrainingExercises(trainingExercise)
            training.insertIntoTrainingExercises(trainingExercise, at: index)
        } else { // all other exercises are already completed
            training.removeFromTrainingExercises(trainingExercise)
            training.addToTrainingExercises(trainingExercise)
        }
        delegate?.exerciseOrderDidChange()
    }
    
    private func selectCurrentSet(animated: Bool) {
        // then select the row of the current exercise
        if let set = currentSet {
            let row = trainingExercise!.trainingSets!.index(of: set)
            let indexPath = IndexPath(row: row, section: 0)
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
            setPickerTo(trainingSet: set, animated: animated)
            tableView.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
        } else {
            if let selected = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selected, animated: animated)
            }
            setPickerTo(trainingSet: nil, animated: animated) // hides the picker
        }
    }
    
    private func setPickerTo(trainingSet: TrainingSet?, animated: Bool) {
        if isEditing {
            return
        }
        if trainingSet == nil {
            hidePickerView(animated: animated)
            actionButton.setTitle(completeExerciseTitle ?? "Complete Exercise", for: .normal)
            return
        }
        
        let weightRows = rowsFor(weight: trainingSet!.weight)
        pickerView.selectRow(rowFor(reps: Int(trainingSet!.repetitions)), inComponent: 0, animated: animated)
        pickerView.selectRow(weightRows.0, inComponent: 1, animated: animated)
        pickerView.selectRow(weightRows.1, inComponent: 2, animated: animated)
        
        if trainingSet == currentSet {
            actionButton.setTitle("Complete Set", for: .normal)
        } else {
            actionButton.setTitle("Ok", for: .normal)
        }

        showPickerView(animated: animated)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        
        if editing {
            hideStackView(animated: animated)
        } else {
            showStackView(animated: animated)
            selectCurrentSet(animated: animated)
        }
    }
    
    @objc
    func addSet() {
        if trainingExercise != nil {
            let wasCompleted = trainingExercise!.isCompleted!

            let trainingSet = TrainingSet(context: trainingExercise!.managedObjectContext!)
            trainingExercise!.addToTrainingSets(trainingSet)
            
            let indexPath = IndexPath(row: trainingExercise!.trainingSets!.count - 1, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            selectCurrentSet(animated: true)
            
            if wasCompleted {
                moveExerciseBehindLastCompleted(trainingExercise: trainingExercise!)
            }
        }
    }
    
    private func trainingSet(of indexPath: IndexPath) -> TrainingSet {
        return trainingExercise!.trainingSets![indexPath.row] as! TrainingSet
    }
    
    private func indexPath(of trainingSet: TrainingSet) -> IndexPath {
        return IndexPath(row: trainingExercise!.trainingSets!.index(of: trainingSet), section: 0)
    }
    
    private func hidePickerView(animated: Bool) {
        self.pickerView.alpha = 0
        UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
            self.pickerView.isHidden = true
            self.stackView.layoutIfNeeded()
        })
    }
    
    private func showPickerView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
            self.pickerView.isHidden = false
            self.stackView.layoutIfNeeded()
        }) { _ in
            self.pickerView.alpha = 1
        }
    }
    
    private func hideStackView(animated: Bool) {
        self.pickerView.alpha = 0
        self.actionButton.alpha = 0
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.pickerView.isHidden = true
            self.actionButton.isHidden = true
            self.stackView.layoutIfNeeded()
        }
    }
    
    private func showStackView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.pickerView.isHidden = false
            self.actionButton.isHidden = false
            self.stackView.layoutIfNeeded()
        }) { _ in
            self.pickerView.alpha = 1
            self.actionButton.alpha = 1
        }
    }
}

extension CurrentTrainingExerciseViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // TODO add more sections for the other days
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return (trainingExercise?.trainingSets?.count ?? 0) + 1 // + 1 for the addSet row
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == trainingExercise?.trainingSets?.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addSetCell", for: indexPath) as! AddSetTableViewCell
            cell.addSetButton.addTarget(self, action: #selector(addSet), for: .touchUpInside)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "setCell", for: indexPath)
        let trainingSet = self.trainingSet(of: indexPath)

        if trainingSet.isCompleted || trainingSet == currentSet {
            cell.textLabel?.text = trainingSet.displayTitle
        } else {
            cell.textLabel?.text = "Set \(indexPath.row + 1)"
        }
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        
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
            let wasCompleted = trainingExercise!.isCompleted!
            
            let trainingSet = self.trainingSet(of: indexPath)
            trainingExercise!.removeFromTrainingSets(trainingSet)
            trainingSet.managedObjectContext?.delete(trainingSet)
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                tableView.reloadSections([0], with: .automatic)
            })
            selectCurrentSet(animated: true)
            
            if !wasCompleted && trainingExercise!.isCompleted! {
                moveExerciseBehindLastCompleted(trainingExercise: trainingExercise!)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if !isEditing {
            return .none // disable swipe to delete
        }
        if indexPath.section == 0 && indexPath.row == trainingExercise?.trainingSets?.count {
            return .none
        }
        if trainingExercise?.trainingSets?.count == 1 {
            return .none // don't allow to delete the last set
        }
        return .delete
    }
}

extension CurrentTrainingExerciseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 && indexPath.row == trainingExercise?.trainingSets?.count {
            return false
        }
        let trainingSet = self.trainingSet(of: indexPath)
        return trainingSet.isCompleted || trainingSet == currentSet
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setPickerTo(trainingSet: self.trainingSet(of: indexPath), animated: true)
    }
}

extension CurrentTrainingExerciseViewController: UIPickerViewDataSource {
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

extension CurrentTrainingExerciseViewController: UIPickerViewDelegate {
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

protocol TrainingExerciseViewControllerDelegate {
    func completeExercise(trainingExerciseViewController: CurrentTrainingExerciseViewController)
    func exerciseOrderDidChange()
}
