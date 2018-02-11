//
//  TrainingViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 10.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class TrainingViewController: UIViewController, ExerciseSelectionHandler {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let exerciseTableViewController = segue.destination as? ExercisesTableViewController {
            exerciseTableViewController.exercises = EverkineticDataProvider.loadExercises()
            exerciseTableViewController.exerciseSelectionHandler = self
            exerciseTableViewController.accessoryType = .none
            exerciseTableViewController.navigationItem.hidesSearchBarWhenScrolling = false
            exerciseTableViewController.title = "Add Exercise"
        }
    }
    
    func handleSelection(exercise: Exercise) {
        navigationController?.popToViewController(self, animated: true)
        // TODO actually add exercise to current training
    }
}
