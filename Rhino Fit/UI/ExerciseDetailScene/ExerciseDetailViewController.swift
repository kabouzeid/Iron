//
//  ExerciseDetailViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 24.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class ExerciseDetailViewController: UITableViewController {
    
    var exercise: Exercise? {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return exercise == nil ? 0 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let exercise = self.exercise! // should never be nil at this point
        switch section {
        case 0: // Image
            return exercise.png.isEmpty ? 0 : 1
        case 1:
            return exercise.primaryMuscle.count + exercise.secondaryMuscle.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Muscles"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = self.exercise! // should never be nil at this point
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ExerciseImageTableViewCell
            
            let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(exercise.png[0])
            if let imageData = try? Data(contentsOf: url) {
                cell.exerciseImage.image = UIImage(data: imageData)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "muscleCell", for: indexPath)
            
            if exercise.primaryMuscle.count > indexPath.row {
                cell.textLabel?.text = "Primary"
                cell.detailTextLabel?.text = exercise.primaryMuscleCommonName[indexPath.row]
            } else {
                cell.textLabel?.text = "Secondary"
                cell.detailTextLabel?.text = exercise.secondaryMuscleCommonName[indexPath.row - exercise.primaryMuscle.count]
            }
            
            return cell
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
