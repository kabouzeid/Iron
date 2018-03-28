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
        durationLabel.text = (training?.end ?? Date()).timeIntervalSince(training?.start ?? Date()).stringFormattedWithLetters()
        let numberOfSets = training?.trainingExercises!.reduce(0, { (count, trainingExercise) -> Int in
            let trainingExercise = trainingExercise as! TrainingExercise
            return count + trainingExercise.trainingSets!.count
        })
        setsLabel.text = "\(numberOfSets ?? 0)"
        let totalWeight = training?.trainingExercises!.reduce(0, { (weight, trainingExercise) -> Float in
            let trainingExercise = trainingExercise as! TrainingExercise
            return weight + trainingExercise.trainingSets!.reduce(0, { (weight, trainingSet) -> Float in
                let trainingSet = trainingSet as! TrainingSet
                return weight + trainingSet.weight
            })
        })
        weightLabel.text = "\((totalWeight ?? 0).clean) kg"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return training?.trainingExercises!.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exercise cell", for: indexPath)

        let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
        cell.textLabel?.text = trainingExercise.exercise?.title
        let setTitles = trainingExercise.trainingSets!.map { ($0 as! TrainingSet).displayTitle }
        cell.detailTextLabel?.text = setTitles.joined(separator: "\n")
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trainingExercise = training!.trainingExercises![indexPath.row] as! TrainingExercise
            training!.removeFromTrainingExercises(trainingExercise)
            trainingExercise.managedObjectContext?.delete(trainingExercise)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            title = training!.displayTitle
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
