//
//  CurrentTrainingExerciseViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class CurrentTrainingExerciseViewController: UIViewController {
    
    var trainingExercise: TrainingExercise? {
        didSet {
            trainingExerciseHistory = trainingExercise?.history!
            title = trainingExercise?.exercise?.title
            tableView?.reloadData()
            if tableView != nil {
                selectCurrentSet(animated: true)
            }
        }
    }
    
    private var trainingExerciseHistory: [TrainingExercise]?

    var completeExerciseTitle: String? {
        didSet {
            if currentSet == nil {
                repWeightPickerView?.button?.setTitle(completeExerciseTitle ?? "Complete Exercise", for: .normal)
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
    
    private let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        repWeightPickerView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        selectCurrentSet(animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var repWeightPickerView: RepWeightPickerView!
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
        training.removeFromTrainingExercises(trainingExercise) // remove before doing the other stuff!
        let firstUncompleted = training.trainingExercises!.first(where: { (exercise) -> Bool in
            let exercise = exercise as! TrainingExercise
            return !exercise.isCompleted!
        })
        if firstUncompleted != nil {
            let firstUncompleted = firstUncompleted! as! TrainingExercise
            let index = training.trainingExercises!.index(of: firstUncompleted)
            training.insertIntoTrainingExercises(trainingExercise, at: index)
        } else { // all other exercises are already completed
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
                if row > 0 { // not the first set
                    let previousSet = trainingExercise!.trainingSets![row - 1] as! TrainingSet
                    set.repetitions = previousSet.repetitions
                    set.weight = previousSet.weight
                } else {
                    if let mostRecentSet = trainingExerciseHistory!.first?.trainingSets?.firstObject as? TrainingSet {
                        // use the most recent values if available
                        set.repetitions = mostRecentSet.repetitions
                        set.weight = mostRecentSet.weight
                    } else {
                        set.repetitions = 1
                    }
                }
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            setRepWeightPickerTo(trainingSet: set, animated: animated)
            tableView.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
        } else {
            if let selected = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selected, animated: animated)
            }
            setRepWeightPickerTo(trainingSet: nil, animated: animated) // hides the picker
        }
    }
    
    private func setRepWeightPickerTo(trainingSet: TrainingSet?, animated: Bool) {
        if isEditing {
            return
        }
        if trainingSet == nil {
            hideRepWeightPickerView(animated: animated)
            repWeightPickerView.button.setTitle(completeExerciseTitle ?? "Complete Exercise", for: .normal)
            return
        }
        
        repWeightPickerView.select(weight: trainingSet!.weight, animated: animated)
        repWeightPickerView.select(repetitions: Int(trainingSet!.repetitions), animated: animated)

        if trainingSet == currentSet {
            repWeightPickerView.button.setTitle("Complete Set", for: .normal)
        } else {
            repWeightPickerView.button.setTitle("Ok", for: .normal)
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
        if indexPath.section == 0 {
            return trainingExercise!.trainingSets![indexPath.row] as! TrainingSet
        } else {
            return trainingExerciseHistory![indexPath.section - 1].trainingSets![indexPath.row] as! TrainingSet
        }
    }
    
    private func indexPath(of trainingSet: TrainingSet) -> IndexPath {
        return IndexPath(row: trainingExercise!.trainingSets!.index(of: trainingSet), section: 0)
    }
    
    private func hideRepWeightPickerView(animated: Bool) {
        repWeightPickerView.pickerView.alpha = 0
        UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
            self.repWeightPickerView.pickerView.isHidden = true
            self.repWeightPickerView.layoutIfNeeded()
        })
    }
    
    private func showPickerView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
            self.repWeightPickerView.pickerView.isHidden = false
            self.repWeightPickerView.layoutIfNeeded()
        }) { _ in
            self.repWeightPickerView.pickerView.alpha = 1
        }
    }
    
    private func hideStackView(animated: Bool) {
        repWeightPickerView.pickerView.alpha = 0
        repWeightPickerView.button.alpha = 0
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.repWeightPickerView.pickerView.isHidden = true
            self.repWeightPickerView.button.isHidden = true
            self.repWeightPickerView.layoutIfNeeded()
        }
    }
    
    private func showStackView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.repWeightPickerView.pickerView.isHidden = false
            self.repWeightPickerView.button.isHidden = false
            self.repWeightPickerView.layoutIfNeeded()
        }) { _ in
            self.repWeightPickerView.pickerView.alpha = 1
            self.repWeightPickerView.button.alpha = 1
        }
    }
}

extension CurrentTrainingExerciseViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + (trainingExerciseHistory?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return (trainingExercise?.trainingSets?.count ?? 0) + 1 // + 1 for the addSet row
        default:
            return trainingExerciseHistory?[section - 1].trainingSets?.count ?? 0
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
            return "Now"
        default:
            return dateFormatter.string(from: trainingExerciseHistory![section - 1].training!.start!)
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
        if indexPath.section != 0 {
            return .none
        }
        return .delete
    }
}

extension CurrentTrainingExerciseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 && indexPath.row == trainingExercise?.trainingSets?.count {
            return false
        }
        if indexPath.section != 0 {
            return false
        }
        let trainingSet = self.trainingSet(of: indexPath)
        return trainingSet.isCompleted || trainingSet == currentSet
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setRepWeightPickerTo(trainingSet: self.trainingSet(of: indexPath), animated: true)
    }
}

extension CurrentTrainingExerciseViewController: RepWeightPickerDelegate {
    func repWeightPickerView(_ repWeightPickerView: RepWeightPickerView, didSelect repetitions: Int) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let trainingExercise = self.trainingSet(of: indexPath)
            trainingExercise.repetitions = Int16(repetitions)
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func repWeightPickerView(_ repWeightPickerView: RepWeightPickerView, didSelect weight: Float) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let trainingExercise = self.trainingSet(of: indexPath)
            trainingExercise.weight = weight
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }
    
    func repWeightPickerViewButtonClicked(_ repWeightPickerView: RepWeightPickerView) {
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
}

protocol TrainingExerciseViewControllerDelegate {
    func completeExercise(trainingExerciseViewController: CurrentTrainingExerciseViewController)
    
    func exerciseOrderDidChange()
}
