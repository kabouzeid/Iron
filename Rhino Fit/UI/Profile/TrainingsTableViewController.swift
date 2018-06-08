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
    
    private var trainings: [Training]?

    private let dateFormatter = DateFormatter()

    @IBOutlet weak var summaryView: SummaryView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO: learn how to implement NSFetchedResultsController
        let request: NSFetchRequest<Training> =  Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        trainings = try? AppDelegate.instance.persistentContainer.viewContext.fetch(request)
        tableView.reloadData()

        updateSummary()
    }
    
    private func updateSummary() {
        let calendar = Calendar(identifier: .iso8601)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -7, to: sevenDaysAgo)!
        
        let sevenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        sevenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@",
                                                 NSNumber(booleanLiteral: true),
                                                 sevenDaysAgo as NSDate)
        guard let trainingsFromSevenDaysAgo = try? AppDelegate.instance.persistentContainer.viewContext.fetch(sevenDaysRequest) else {
            return
        }
        
        let fourteenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        fourteenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@ AND start < %@",
                                                    NSNumber(booleanLiteral: true),
                                                    fourteenDaysAgo as NSDate,
                                                    sevenDaysAgo as NSDate)
        guard let trainingsFromFourteenDaysAgo = try? AppDelegate.instance.persistentContainer.viewContext.fetch(fourteenDaysRequest) else {
            return
        }
        
        let valuesSevenDaysAgo = trainingsFromSevenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Float) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }
        let valuesFourTeenDaysAgo = trainingsFromFourteenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Float) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }

        let durationEntry = summaryView.entries[0]
        let setsEntry = summaryView.entries[1]
        let weightEntry = summaryView.entries[2]

        durationEntry.title.text = "Duration\nLast 7 Days"
        setsEntry.title.text = "Sets\nLast 7 Days"
        weightEntry.title.text = "Weight\nLast 7 Days"

        durationEntry.text.text = valuesSevenDaysAgo.0.stringFormattedWithLetters()
        setsEntry.text.text = "\(valuesSevenDaysAgo.1)"
        weightEntry.text.text = "\(valuesSevenDaysAgo.2.clean) kg"
        
        var durationPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.0 / valuesFourTeenDaysAgo.0) - 1) * 100)
        durationPercent = abs(durationPercent) < 0.1 ? 0 : durationPercent
        if durationPercent > 0 {
            durationEntry.detail.textColor = UIColor.appleGreen
            durationEntry.detail.text = "+"
        } else if durationPercent < 0 {
            durationEntry.detail.textColor = UIColor.appleRed
            durationEntry.detail.text = ""
        } else {
            durationEntry.detail.textColor = UIColor.darkGray
            durationEntry.detail.text = "+"
        }
        durationEntry.detail.text! += String(format: "%.1f", durationPercent) + "%"
        durationEntry.detail.isHidden = false
        
        var setsPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((Float(valuesSevenDaysAgo.1) / Float(valuesFourTeenDaysAgo.1)) - 1) * 100)
        setsPercent = abs(setsPercent) < 0.1 ? 0 : setsPercent
        if setsPercent > 0 {
            setsEntry.detail.textColor = UIColor.appleGreen
            setsEntry.detail.text = "+"
        } else if setsPercent < 0 {
            setsEntry.detail.textColor = UIColor.appleRed
            setsEntry.detail.text = ""
        } else {
            setsEntry.detail.textColor = UIColor.darkGray
            setsEntry.detail.text = "+"
        }
        setsEntry.detail.text! += String(format: "%.1f", setsPercent) + "%"
        setsEntry.detail.isHidden = false
        
        var weightPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.2 / valuesFourTeenDaysAgo.2) - 1) * 100)
        weightPercent = abs(weightPercent) < 0.1 ? 0 : weightPercent
        if weightPercent > 0 {
            weightEntry.detail.textColor = UIColor.appleGreen
            weightEntry.detail.text = "+"
        } else if weightPercent < 0 {
            weightEntry.detail.textColor = UIColor.appleRed
            weightEntry.detail.text = ""
        } else {
            weightEntry.detail.textColor = UIColor.darkGray
            weightEntry.detail.text = "+"
        }
        weightEntry.detail.text! += String(format: "%.1f", weightPercent) + "%"
        weightEntry.detail.isHidden = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // TODO section for this week, this month etc.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trainings?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "training cell", for: indexPath)
        let training = trainings![indexPath.row]
        
        cell.textLabel?.text = training.displayTitle
        cell.detailTextLabel?.text = "\(dateFormatter.string(from: training.start!)) for \(training.end!.timeIntervalSince(training.start!).stringFormattedWithLetters())"

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            trainings![indexPath.row].managedObjectContext?.delete(trainings![indexPath.row])
            trainings!.remove(at: indexPath.row)
            AppDelegate.instance.saveContext()
            tableView.deleteRows(at: [indexPath], with: .automatic)

            updateSummary()
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
