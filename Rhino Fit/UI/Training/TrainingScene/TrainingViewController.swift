//
//  TrainingViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 10.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class TrainingViewController: UIViewController, ExerciseSelectionHandler, UITableViewDelegate, UITableViewDataSource {
    
    var training: Training? {
        didSet {
            title = training?.title
            tableView?.reloadData()
            if startTimerButton != nil, elapsedTimeLabel != nil, timeLabel != nil {
                updateTimerViewState(animated: false)
            }
        }
    }
    
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItems?.append(editButtonItem)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
        
        updateTimerViewState(animated: false)
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startTimerButton: UIButton!
    @IBAction func startTimer(_ sender: UIButton) {
        if training?.start == nil {
            training?.start = Date()
        }
        updateTimerViewState(animated: true)
    }
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    private func updateTimerViewState(animated: Bool) {
        if self.training?.start != nil {
            UIView.animate(withDuration: animated ? 0.3 : 0) {
                self.startTimerButton.isHidden = true
                self.startTimerButton.alpha = 0
                self.elapsedTimeLabel.isHidden = false
                self.elapsedTimeLabel.alpha = 1
                self.timeLabel.isHidden = false
                self.timeLabel.alpha = 1
            }
            startUpdateTimeLabel()
        } else {
            UIView.animate(withDuration: animated ? 0.3 : 0) {
                self.startTimerButton.isHidden = false
                self.startTimerButton.alpha = 1
                self.elapsedTimeLabel.isHidden = true
                self.elapsedTimeLabel.alpha = 0
                self.timeLabel.isHidden = true
                self.timeLabel.alpha = 0
            }
            stopUpdateTimeLabel()
        }
    }
    
    private func startUpdateTimeLabel() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
                if let elapsedTime = self.training?.start?.timeIntervalSinceNow {
                    self.timeLabel.text = (-elapsedTime).stringFormatted()
                }
            })
        }
        timer?.fire()
    }
    
    private func stopUpdateTimeLabel() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: Data Source
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let trainingExercise = training!.trainingExercises![sourceIndexPath.row] as! TrainingExercise
        training!.removeFromTrainingExercises(trainingExercise)
        training!.insertIntoTrainingExercises(trainingExercise, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return !(training!.trainingExercises![indexPath.row] as! TrainingExercise).isCompleted!
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return (training!.trainingExercises![proposedDestinationIndexPath.row] as! TrainingExercise).isCompleted! ? sourceIndexPath : proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
            training!.removeFromTrainingExercises(trainingExercise)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return training?.trainingExercises?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell", for: indexPath)
        // TODO
        let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
        let completedSets = trainingExercise.numberOfCompletedSets!
        let totalSets = trainingExercise.trainingSets!.count
        cell.textLabel?.text = trainingExercise.exercise?.title
        cell.detailTextLabel?.text = "\(completedSets) of \(totalSets)"
        if completedSets == totalSets { // completed exercise
            cell.textLabel?.textColor = UIColor.lightGray
            cell.detailTextLabel?.textColor = UIColor.lightGray
        } else {
            cell.textLabel?.textColor = UIColor.darkText
            cell.detailTextLabel?.textColor = UIColor.darkGray
        }
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let exerciseTableViewController = segue.destination as? ExercisesTableViewController {
            exerciseTableViewController.exercises = EverkineticDataProvider.exercises
            exerciseTableViewController.exerciseSelectionHandler = self
            exerciseTableViewController.accessoryType = .none
            exerciseTableViewController.navigationItem.hidesSearchBarWhenScrolling = false
            exerciseTableViewController.title = "Add Exercise"
        } else if let trainingExercisePageViewController = segue.destination as? TrainingExercisePageViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            trainingExercisePageViewController.initialTrainingExercise = (training!.trainingExercises![indexPath.row] as! TrainingExercise)
        } else if segue.identifier == "cancel training" {
            if training?.managedObjectContext != nil {
                Training.deleteCurrentTraining(context: training!.managedObjectContext!)
                try? training!.managedObjectContext!.save()
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func handleSelection(exercise: Exercise) {
        navigationController?.popToViewController(self, animated: true)
        
        if training?.managedObjectContext == nil {
            return
        }
        
        let trainingExercise = TrainingExercise(context: training!.managedObjectContext!)
        trainingExercise.exerciseId = Int16(exercise.id)
        trainingExercise.training = training
        trainingExercise.addToTrainingSets(createDefaultTrainingSets())
        
        tableView.reloadData()
    }

    private func createDefaultTrainingSets() -> NSOrderedSet {
        var trainingSets = [TrainingSet]()
        
        if training?.managedObjectContext == nil {
            return NSOrderedSet(array: trainingSets)
        }
        
        for _ in 0...3 {
            let trainingSet = TrainingSet(context: training!.managedObjectContext!)
            // TODO add default reps and weight
            trainingSets.append(trainingSet)
        }
        return NSOrderedSet(array: trainingSets)
    }
}
