//
//  ExerciseHistoryTableViewController.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.04.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class ExerciseHistoryTableViewController: UITableViewController {
    
    var scrollTo: Int? // optional
    var trainingExercises: [TrainingExercise]? {
        didSet {
            tableView?.reloadData()
            checkScrollTo()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkScrollTo()
    }
    
    private func checkScrollTo() {
        if let scrollTo = scrollTo {
            tableView?.scrollToRow(at: IndexPath(row: 0, section: scrollTo), at: .top, animated: false)
            self.scrollTo = nil
        }
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
        cell.textLabel?.text = trainingSet.displayTitle(unit: .metric)
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        
//        cell.textLabel?.textColor = UIColor.darkText
//        cell.detailTextLabel?.textColor = UIColor.darkGray
        
//        cell.textLabel?.textColor = UIColor.lightGray
//        cell.detailTextLabel?.textColor = UIColor.lightGray

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Training.dateFormatter.string(from: trainingExercises![section].training!.start!)
    }
}
