//
//  ExercisesTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import SwiftyJSON
import Benchmark

class ExercisesTableViewController: UITableViewController, UISearchResultsUpdating {
    
    // MARK: - Model
    
    var exercises: [Exercise] = {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent("exercises.json")
        if let jsonString = try? String(contentsOf: jsonUrl) {
            return EverkineticParser.parse(jsonString: jsonString)
        }
        return []
        }() {
        didSet {
            filterExercises(by: filterText, force: true)
        }
    }
    
    private var displayExercises = [Exercise]() {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Search
    
    private var filterText = ""
    
    func updateSearchResults(for searchController: UISearchController) {
        filterExercises(by: searchController.searchBar.text!)
    }
    
    func filterExercises(by: String, force : Bool = false) {
        if force || filterText != by.lowercased() {
            filterText = by.lowercased()
            displayExercises = exercises.filter { exercise in
                if filterText.isEmpty {
                    return true
                }
                return exercise.title.lowercased().contains(filterText)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        filterExercises(by: filterText, force: true)
        
        tableView.rowHeight = 80
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.searchResultsUpdater = self
    }
    
    override func didReceiveMemoryWarning() {
        imageCache = [:]
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayExercises.count
    }
    
    var imageCache = [Int: UIImage]()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exercise", for: indexPath) as! ExerciseTableViewCell

        // Clear data
        let exercise = displayExercises[indexPath.row]
        cell.exerciseTitle.text = exercise.title
        cell.exerciseDetail.text = exercise.description
        cell.exerciseImage.image = imageCache[exercise.id]

        if cell.exerciseImage.image == nil && !exercise.png.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(exercise.png[0])
                if let imageData = try? Data(contentsOf: url) {
                    let image = UIImage(data: imageData)
                    self?.imageCache[exercise.id] = image
                    DispatchQueue.main.async {
                        if let originalCell = tableView.cellForRow(at: indexPath) as? ExerciseTableViewCell {
                            originalCell.exerciseImage.image = image
                            originalCell.layoutSubviews()
                        }
                    }
                }
            }
        }

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
