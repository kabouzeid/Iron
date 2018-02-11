//
//  ExercisesTableViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import SwiftyJSON

class ExercisesTableViewController: UITableViewController, UISearchResultsUpdating {
    
    var exerciseSelectionHandler: ExerciseSelectionHandler?
    var accessoryType: UITableViewCellAccessoryType = .disclosureIndicator {
        didSet {
            if tableView != nil {
                tableView.reloadData()
            }
        }
    }

    // MARK: - Model
    
    var exercises = [Exercise]() {
        didSet {
            filterExercises(by: filterText, force: true)
        }
    }
    
    private var displayExercises = [[Exercise]]() {
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
            displayExercises = EverkineticDataProvider.splitIntoMuscleGroups(exercises: exercises.filter { exercise in
                if filterText.isEmpty {
                    return true
                }
                return exercise.title.lowercased().contains(filterText)
            })
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterExercises(by: filterText, force: true)
        
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.searchResultsUpdater = self
        
        definesPresentationContext = true // prevents black screen when switching tabs while searching
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayExercises.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayExercises[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if displayExercises.count > 1 {
            return displayExercises[section][0].muscleGroup.capitalized
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exerciseCell", for: indexPath)

        let exercise = displayExercises[indexPath.section][indexPath.row]
        cell.textLabel?.text = exercise.title
        cell.accessoryType = accessoryType

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let exerciseDetailPresenter = exerciseSelectionHandler {
            exerciseDetailPresenter.handleSelection(exercise: displayExercises[indexPath.section][indexPath.row])
            tableView.deselectRow(at: indexPath, animated: true) // willAppear not called when comming back
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let exerciseDetailViewController = segue.destination as? ExerciseDetailViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            let exercise = displayExercises[indexPath.section][indexPath.row]
            exerciseDetailViewController.exercise = exercise
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !(sender is UITableViewCell) || exerciseSelectionHandler == nil // sender is cell => delegate = nil
    }
}

protocol ExerciseSelectionHandler {
    func handleSelection(exercise: Exercise)
}
