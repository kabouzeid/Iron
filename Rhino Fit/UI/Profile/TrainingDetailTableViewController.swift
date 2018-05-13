//
//  TrainingDetailTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 17.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class TrainingDetailTableViewController: UITableViewController {
    
    var training: Training? {
        didSet {
            title = training?.displayTitle
            tableView?.reloadData()
            if summaryView != nil {
                updateSummary()
            }
        }
    }

    var isEditable = false {
        didSet {
            self.navigationItem.rightBarButtonItem = isEditable ? self.editButtonItem : nil
        }
    }
    
    private var sectionKeys = ["exercises"]
    private let dateFormatter = DateFormatter()
    private var previousSelectedDate = SelectedDate.none
    private var selectedDate = SelectedDate.none {
        willSet {
            previousSelectedDate = selectedDate
        }
        didSet {
            if let index = sectionKeys.index(of: "duration") {
                if previousSelectedDate != selectedDate {

                    tableView.performBatchUpdates({
                        if previousSelectedDate == .start {
                            tableView.deleteRows(at: [IndexPath(row: 1, section: index)], with: .fade)
                        }
                        if previousSelectedDate == .end {
                            tableView.deleteRows(at: [IndexPath(row: 2, section: index)], with: .fade)
                        }
                        if selectedDate == .start {
                            tableView.insertRows(at: [IndexPath(row: 1, section: index)], with: .fade)
                        }
                        if selectedDate == .end {
                            tableView.insertRows(at: [IndexPath(row: 2, section: index)], with: .fade)
                        }

                    }) { _ in
                        // clears the selection and updates the colors of the start/end cells
                        self.tableView.reloadRows(at: [IndexPath(row: self.durationCellIndexFor(type: .start), section: index),
                                                       IndexPath(row: self.durationCellIndexFor(type: .end), section: index)], with: .automatic)
                    }
                }
            }
        }
    }
    
    private enum SelectedDate {
        case none
        case start
        case end
    }

    private enum DurationCellType {
        case datePicker
        case start
        case end
    }

    @IBOutlet weak var summaryView: SummaryView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: use NSFetchedResultsController
        tableView.reloadData()
        updateSummary()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if isEditable {
            if editing {
                if !notReallyInEditingMode && !sectionKeys.contains("duration") {
                    sectionKeys.insert("duration", at: 0)
                    tableView.insertSections([0], with: .automatic)
                }
            } else {
                if let index = sectionKeys.index(of: "duration") {
                    sectionKeys.remove(at: index)
                    tableView.deleteSections([index], with: .automatic)
                }
                selectedDate = .none
            }
        }
        notReallyInEditingMode = false // reset this flag after setEditing() is called
    }
    
    private func updateSummary() {
        let durationEntry = summaryView.entries[0]
        let setsEntry = summaryView.entries[1]
        let weightEntry = summaryView.entries[2]

        durationEntry.title.text = "Duration"
        setsEntry.title.text = "Sets"
        weightEntry.title.text = "Weight"

        durationEntry.text.text = training?.duration.stringFormattedWithLetters()
        setsEntry.text.text = "\(training?.numberOfCompletedSets ?? 0)"
        weightEntry.text.text = "\((training?.totalCompletedWeight ?? 0).clean) kg"
    }

    private func durationCellType(at: Int) -> DurationCellType {
        switch at {
        case 0:
            return .start
        case 1:
            return selectedDate == .start ? .datePicker : .end
        case 2:
            guard selectedDate != .none else {
                fatalError("Invalid index")
            }
            return selectedDate == .start ? .end : .datePicker
        default:
            fatalError("Invalid index")
        }
    }

    private func durationCellIndexFor(type: DurationCellType) -> Int {
        return durationCellIndexFor(type: type, selectedDate: selectedDate)
    }

    private func durationCellIndexFor(type: DurationCellType, selectedDate: SelectedDate) -> Int {
        switch type {
        case .datePicker:
            guard selectedDate != .none else {
                fatalError("Asked for index of datepicker while datepicker was not visible")
            }
            return selectedDate == .start ? 1 : 2
        case .start:
            return 0
        case .end:
            return selectedDate == .start ? 2 : 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionKeys[section] {
        case "duration":
            return selectedDate == .none ? 2 : 3
        case "exercises":
            return training?.trainingExercises!.count ?? 0
        default:
            fatalError("No section key for section \(section).")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sectionKeys[indexPath.section] {
        case "duration":
            switch durationCellType(at: indexPath.row) {
            case .datePicker:
                let cell = tableView.dequeueReusableCell(withIdentifier: "date picker cell", for: indexPath) as! DatePickerTableViewCell
                cell.delegate = self
                if selectedDate == .start {
                    cell.datePicker.setDate(training!.start!, animated: false)
                    cell.datePicker.minimumDate = nil
                    cell.datePicker.maximumDate = training!.end!
                } else {
                    cell.datePicker.setDate(training!.end!, animated: false)
                    cell.datePicker.minimumDate = training!.start!
                    cell.datePicker.maximumDate = nil
                }
                return cell
            case .start, .end:
                let cell = tableView.dequeueReusableCell(withIdentifier: "duration cell", for: indexPath)
                cell.textLabel?.text = indexPath.row == 0 ? "Start" : "End"
                cell.detailTextLabel?.text = dateFormatter.string(from: indexPath.row == 0 ? training!.start! : training!.end!)
                cell.detailTextLabel?.textColor = selectedDate == .start && indexPath.row == 0 || selectedDate == .end && indexPath.row == 1 ? cell.detailTextLabel?.tintColor : UIColor.black
                return cell
            }
        case "exercises":
            let cell = tableView.dequeueReusableCell(withIdentifier: "exercise cell", for: indexPath)
            cell.accessoryType = isEditable ? .disclosureIndicator : .none
            
            let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
            cell.textLabel?.text = trainingExercise.exercise?.title
            let setTitles = trainingExercise.trainingSets!.map { ($0 as! TrainingSet).displayTitle }
            cell.detailTextLabel?.text = setTitles.joined(separator: "\n")
            
            return cell
        default:
            fatalError("No section key for section \(indexPath.section).")
        }

    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditable && sectionKeys[indexPath.section] == "exercises"
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if sectionKeys[indexPath.section] == "exercises" {
                let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
                training!.removeFromTrainingExercises(trainingExercise)
                trainingExercise.managedObjectContext?.delete(trainingExercise)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                title = training!.displayTitle
                updateSummary()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if sectionKeys[indexPath.section] == "duration" {
            switch durationCellType(at: indexPath.row) {
            case .datePicker:
                return false
            case .start, .end:
                return isEditable
            }
        }
        return isEditable && !isEditing
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sectionKeys[indexPath.section] == "duration" {
            switch durationCellType(at: indexPath.row) {
            case .datePicker:
                // do nothing
                break
            case .start:
                // toggle start
                selectedDate = selectedDate == .start ? .none : .start
            case .end:
                // toggle end
                selectedDate = selectedDate == .end ? .none : .end
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let currentTrainingExerciseViewController = segue.destination as? CurrentTrainingExerciseViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            currentTrainingExerciseViewController.trainingExercise = training!.trainingExercises![indexPath.row] as? TrainingExercise
        }
    }
    
    var notReallyInEditingMode = false // a small hack necessary because when swiping to delete setEditing() is called
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        notReallyInEditingMode = true
        super.tableView(tableView, willBeginEditingRowAt: indexPath)
    }
}

extension TrainingDetailTableViewController: DatePickerTableViewCellDelegate {
    func dateChanged(date: Date) {
        switch selectedDate {
        case .start:
            if date <= training!.end! { // should not be necessary, but just to be safe
                training!.start = date
                tableView.reloadRows(at: [IndexPath(row: durationCellIndexFor(type: .start), section: sectionKeys.index(of: "duration")!)], with: .automatic)
                updateSummary()
            }
        case .end:
            if date >= training!.start! { // should not be necessary, but just to be safe
                training!.end = date
                tableView.reloadRows(at: [IndexPath(row: durationCellIndexFor(type: .end), section: sectionKeys.index(of: "duration")!)], with: .automatic)
                updateSummary()
            }
        default:
            print("date changed called, but no date selected") // should never happen
            return
        }
    }
}
