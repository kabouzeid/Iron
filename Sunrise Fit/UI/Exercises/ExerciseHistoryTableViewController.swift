//
//  ExerciseHistoryTableViewController.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.04.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class ExerciseHistoryTableViewController: UITableViewController {
    
    var trainingExercises: [TrainingExercise]? {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return trainingExercises?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trainingExercises?[section].trainingSets?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setCell", for: indexPath)
        let trainingSet = trainingExercises![indexPath.section].trainingSets![indexPath.row] as! TrainingSet
        
        assert(trainingSet.isCompleted)
        cell.textLabel?.text = trainingSet.displayTitle
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        
//        cell.textLabel?.textColor = UIColor.darkText
//        cell.detailTextLabel?.textColor = UIColor.darkGray
        
//        cell.textLabel?.textColor = UIColor.lightGray
//        cell.detailTextLabel?.textColor = UIColor.lightGray

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        assert(trainingExercises?[section].training?.isCompleted ?? false)
        return Training.dateFormatter.string(from: trainingExercises![section].training!.start!)
    }
}