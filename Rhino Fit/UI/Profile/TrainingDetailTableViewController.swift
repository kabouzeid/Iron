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
            if durationLabel != nil && setsLabel != nil && weightLabel != nil {
                setLabels()
            }
        }
    }
    
    var isEditable = false {
        didSet {
            self.navigationItem.rightBarButtonItem = isEditable ? self.editButtonItem : nil
        }
    }
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var setsLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLabels()
    }
    
    func setLabels() {
        durationLabel.text = training?.duration.stringFormattedWithLetters()
        setsLabel.text = "\(training?.numberOfSets ?? 0)"
        weightLabel.text = "\((training?.totalWeight ?? 0).clean) kg"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return training?.trainingExercises!.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exercise cell", for: indexPath)
        cell.accessoryType = isEditable ? .disclosureIndicator : .none

        let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
        cell.textLabel?.text = trainingExercise.exercise?.title
        let setTitles = trainingExercise.trainingSets!.map { ($0 as! TrainingSet).displayTitle }
        cell.detailTextLabel?.text = setTitles.joined(separator: "\n")
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditable
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if isEditable && editingStyle == .delete {
            let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
            training!.removeFromTrainingExercises(trainingExercise)
            trainingExercise.managedObjectContext?.delete(trainingExercise)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            title = training!.displayTitle
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return isEditable
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let currentTrainingExerciseViewController = segue.destination as? CurrentTrainingExerciseViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            currentTrainingExerciseViewController.trainingExercise = training!.trainingExercises![indexPath.row] as? TrainingExercise
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "show exercise" {
            return isEditable
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}
