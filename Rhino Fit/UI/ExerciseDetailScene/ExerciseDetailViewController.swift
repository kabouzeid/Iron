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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return tableView.frame.width * (1/1.61) // golden ratio
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return exercise == nil ? 0 : 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let exercise = self.exercise! // should never be nil at this point
        switch section {
        case 0:
            return exercise.png.isEmpty ? 0 : 1
        case 1:
            return exercise.description.isEmpty ? 0 : 1
        case 2:
            return exercise.primaryMuscleCommonName.count + exercise.secondaryMuscleCommonName.count
        case 3:
            return exercise.steps.count
        case 4:
            return exercise.tips.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return nil
        }
        switch section {
        case 2:
            return "Muscles"
        case 3:
            return "Steps"
        case 4:
            return "Tips"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = self.exercise! // should never be nil at this point
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ExerciseImageTableViewCell
            
            var images = [UIImage]()
            for png in exercise.png {
                let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(png)
                if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }
            
            cell.exerciseImage.animationImages = images
            cell.exerciseImage.animationDuration = 2.5
            cell.exerciseImage.startAnimating()
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
            
            cell.textLabel?.text = exercise.description
            
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "muscleCell", for: indexPath)
            
            if exercise.primaryMuscleCommonName.count > indexPath.row {
                cell.textLabel?.text = "Primary"
                cell.detailTextLabel?.text = exercise.primaryMuscleCommonName[indexPath.row].capitalized
            } else {
                cell.textLabel?.text = "Secondary"
                cell.detailTextLabel?.text = exercise.secondaryMuscleCommonName[indexPath.row - exercise.primaryMuscleCommonName.count].capitalized
            }
            
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
            
            cell.textLabel?.text = exercise.steps[indexPath.row]
            
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
            
            cell.textLabel?.text = exercise.tips[indexPath.row]

            return cell
        default:
            return UITableViewCell() // should never happen
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
