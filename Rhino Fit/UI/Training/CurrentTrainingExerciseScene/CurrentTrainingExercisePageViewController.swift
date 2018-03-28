//
//  CurrentTrainingExercisePageViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class CurrentTrainingExercisePageViewController: UIPageViewController {
    var initialTrainingExercise: TrainingExercise? {
        didSet {
            let viewController = instantiateTrainingExerciseViewController(with: initialTrainingExercise!)
            setViewControllers([viewController], direction: .forward, animated: true)
            title = viewControllers![0].title
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.white
        
        navigationItem.rightBarButtonItem = self.editButtonItem
        navigationItem.rightBarButtonItems?.append(UIBarButtonItem.init(image: #imageLiteral(resourceName: "info"), style: .plain, target: self, action: #selector(showExercise)))
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Set", style: .plain, target: nil, action: nil) // when navigating to other VCs show only a short back button title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // workaround for iOS 11 bug
        self.navigationController?.navigationBar.tintAdjustmentMode = .normal
        self.navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }
    
    @objc
    private func showExercise() {
        performSegue(withIdentifier: "show exercise detail", sender: self)
    }
    
    private func instantiateTrainingExerciseViewController(with trainingExercise: TrainingExercise) -> CurrentTrainingExerciseViewController {
        let trainingExerciseViewController = UIStoryboard(name: "Training", bundle: nil).instantiateViewController(withIdentifier: "TrainingExerciseViewController") as! CurrentTrainingExerciseViewController
        trainingExerciseViewController.trainingExercise = trainingExercise
        trainingExerciseViewController.completeExerciseTitle = completeExerciseTitle(exercise: trainingExercise)
        trainingExerciseViewController.delegate = self
        return trainingExerciseViewController
    }
    
    private func allOtherExercisesCompleted(exercise: TrainingExercise) -> Bool {
        let fetchRequest: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "training == %@ AND SELF != %@ AND NOT (ANY trainingSets.isCompleted == %@)", exercise.training!, exercise, NSNumber(booleanLiteral: false))
        _ = exercise.training!.isCompleted
        if let count = try? exercise.managedObjectContext?.count(for: fetchRequest), let total = exercise.training?.trainingExercises?.count {
            return count == total - 1
        }
        return false
    }
    
    private func completeExerciseTitle(exercise: TrainingExercise?) -> String? {
        if exercise == nil { // should actually never happen
            return ""
        }
        return allOtherExercisesCompleted(exercise: exercise!) ? "Finish Training" : "Next Exercise"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if let trainingExerciseViewController = viewControllers?[0], trainingExerciseViewController.isEditing != editing {
            // only set if neccessary
            trainingExerciseViewController.setEditing(editing, animated: animated)
        }
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let exerciseDetailViewController = segue.destination as? ExerciseDetailViewController,
            let trainingExerciseViewController = viewControllers?[0] as? CurrentTrainingExerciseViewController {
            exerciseDetailViewController.exercise = trainingExerciseViewController.trainingExercise?.exercise
        } else if segue.identifier == "finish training",
            let training = (viewControllers?[0] as? CurrentTrainingExerciseViewController)?.trainingExercise!.training! {
            assert(training.isCompleted!, "Attempted to finish uncompleted training!")
            training.isCurrentTraining = false
            training.start = training.start ?? Date() // just to be sure
            training.end = Date()
            
            AppDelegate.instance.saveContext()
        } else if let trainingDetailViewController = segue.destination as? TrainingDetailTableViewController,
            let training = (viewControllers?[0] as? CurrentTrainingExerciseViewController)?.trainingExercise!.training! {
            trainingDetailViewController.training = training
            trainingDetailViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(finishTraining))
        }
    }
    
    @objc
    private func finishTraining() {
        performSegue(withIdentifier: "finish training", sender: viewControllers?[0])
    }

}

extension CurrentTrainingExercisePageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let trainingExercise = trainingExerciseBefore(trainingExercise: (viewController as! CurrentTrainingExerciseViewController).trainingExercise) {
            return instantiateTrainingExerciseViewController(with: trainingExercise)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let trainingExercise = trainingExerciseAfter(trainingExercise: (viewController as! CurrentTrainingExerciseViewController).trainingExercise) {
            return instantiateTrainingExerciseViewController(with: trainingExercise)
        }
        return nil
    }
    
    func trainingExerciseBefore(trainingExercise: TrainingExercise?) -> TrainingExercise? {
        if let trainingExercises = trainingExercise?.training?.trainingExercises {
            let newIndex = trainingExercises.index(of: trainingExercise!) - 1
            if newIndex >= 0 {
                return (trainingExercises[newIndex] as! TrainingExercise)
            }
        }
        return nil
    }
    
    func trainingExerciseAfter(trainingExercise: TrainingExercise?) -> TrainingExercise? {
        if let trainingExercises = trainingExercise?.training?.trainingExercises {
            let newIndex = trainingExercises.index(of: trainingExercise!) + 1
            if newIndex < trainingExercises.count {
                return (trainingExercises[newIndex] as! TrainingExercise)
            }
        }
        return nil
    }
}

extension CurrentTrainingExercisePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let newViewController = pageViewController.viewControllers?[0] {
            title = newViewController.title
            isEditing = newViewController.isEditing
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let newViewController = pendingViewControllers[0] as? CurrentTrainingExerciseViewController {
            newViewController.completeExerciseTitle = completeExerciseTitle(exercise: newViewController.trainingExercise)
        }
    }
}

extension CurrentTrainingExercisePageViewController: TrainingExerciseViewControllerDelegate {
    func completeExercise(trainingExerciseViewController: CurrentTrainingExerciseViewController) {
        if let trainingExercise = trainingExerciseViewController.trainingExercise, trainingExercise.training!.isCompleted! {
            performSegue(withIdentifier: "show training detail", sender: self) // user can finish from there
        } else if let trainingExercise = trainingExerciseAfter(trainingExercise: trainingExerciseViewController.trainingExercise) {
            initialTrainingExercise = trainingExercise
        } else {
            fatalError("Exercises seem to be in wrong order!") // should never happen
        }
    }
    
    func exerciseOrderDidChange() {
        // workaround for removing the cached before and after VCs
        dataSource = nil
        dataSource = self
    }
}
