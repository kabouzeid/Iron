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
    
    private var persistentContainer = AppDelegate.instance.persistentContainer

    private var _training: Training?
    private var training: Training {
        get {
            if (_training == nil) {
                _training = fetchOrCreateCurrentTraining()
            }
            return _training!
        }
        set {
            _training = newValue
        }
    }
    
    private func fetchOrCreateCurrentTraining() -> Training {
        // check if there already is a current training
        if let fetchedTraining = Training.fetchCurrentTraining(context: persistentContainer.viewContext) {
            return fetchedTraining
        } else {
            // otherwise create a new one
            let training = Training(context: persistentContainer.viewContext)
            training.isCurrentTraining = true
            training.date = Date()
            return training
        }
    }
        
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
    }

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Data Source
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let trainingExercise = training.trainingExercises![sourceIndexPath.row] as! TrainingExercise
        training.removeFromTrainingExercises(trainingExercise)
        training.insertIntoTrainingExercises(trainingExercise, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trainingExercise = training.trainingExercises![indexPath.row] as! TrainingExercise
            training.removeFromTrainingExercises(trainingExercise)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let exerciseArray = training.trainingExercises {
            return exerciseArray.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell", for: indexPath)
        // TODO
        let trainingExercise = training.trainingExercises![indexPath.row] as! TrainingExercise
        let completedSets = trainingExercise.completedSets ?? 0
        let totalSets = trainingExercise.trainingSets?.count ?? 0
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
            trainingExercisePageViewController.initialTrainingExercise = (training.trainingExercises![indexPath.row] as! TrainingExercise)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func handleSelection(exercise: Exercise) {
        navigationController?.popToViewController(self, animated: true)
        
        let trainingExercise = TrainingExercise(context: persistentContainer.viewContext)
        trainingExercise.exerciseId = Int16(exercise.id)
        trainingExercise.training = training
        trainingExercise.addToTrainingSets(createDefaultTrainingSets())
        
        tableView.reloadData()
    }

    private func createDefaultTrainingSets() -> NSOrderedSet {
        var trainingSets = [TrainingSet]()
        for _ in 0...3 {
            let trainingSet = TrainingSet(context: persistentContainer.viewContext)
            // TODO add default reps and weight
            trainingSets.append(trainingSet)
        }
        return NSOrderedSet(array: trainingSets)
    }
}
