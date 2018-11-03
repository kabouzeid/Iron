//
//  RecentTrainingsTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 03.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class TrainingsTableViewController: UITableViewController {

    private static let fetchRequest: NSFetchRequest<Training> = {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        return request
    }()

    private var trainings: [Training]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        let fetchedTrainings = try? AppDelegate.instance.persistentContainer.viewContext.fetch(TrainingsTableViewController.fetchRequest)
        if trainings?.count != fetchedTrainings?.count {
            // at least one new training and we don't know at which position
            trainings = fetchedTrainings
            tableView.reloadData()
        } else if let selection = tableView.indexPathForSelectedRow,
            trainings!.first!.objectID == fetchedTrainings?.first?.objectID {
            // no new trainings were added and the selected training did not move from its position
            tableView.reloadRows(at: [selection], with: .none)
            tableView.selectRow(at: selection, animated: false, scrollPosition: .none)
        }

        super.viewWillAppear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO: section for this week, this month etc.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trainings?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "training cell", for: indexPath)
        let training = trainings![indexPath.row]

        cell.textLabel?.text = training.displayTitle
        cell.detailTextLabel?.text = "\(Training.dateFormatter.string(from: training.start!)) for \(Training.durationFormatter.string(from: training.duration)!)"

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let training = trainings![indexPath.row]
            trainings?.remove(at: indexPath.row)
            AppDelegate.instance.persistentContainer.viewContext.delete(training)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let trainingDetailTableViewController = segue.destination as? TrainingDetailTableViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            trainingDetailTableViewController.training = trainings![indexPath.row]
            trainingDetailTableViewController.isEditable = true
        }
    }
}
