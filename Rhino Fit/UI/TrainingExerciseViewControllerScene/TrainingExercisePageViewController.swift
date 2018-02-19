//
//  TrainingExercisePageViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit
import CoreData

class TrainingExercisePageViewController: UIPageViewController {
    
    var initialTrainingExercise: TrainingExercise? {
        didSet {
            setViewControllers([instantiateTrainingExerciseViewController(with: initialTrainingExercise!)], direction: .forward, animated: true)
            title = viewControllers![0].title
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.white
        
        navigationItem.rightBarButtonItem = self.editButtonItem
        navigationItem.rightBarButtonItems?.append(UIBarButtonItem.init(title: "Show", style: .plain, target: self, action: #selector(showExercise)))
        
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
    
    private func instantiateTrainingExerciseViewController(with trainingExercise: TrainingExercise) -> TrainingExerciseViewController {
        let trainingExerciseViewController = UIStoryboard(name: "Training", bundle: nil).instantiateViewController(withIdentifier: "TrainingExerciseViewController") as! TrainingExerciseViewController
        trainingExerciseViewController.trainingExercise = trainingExercise
        return trainingExerciseViewController
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
        if let exerciseDetailViewController = segue.destination as? ExerciseDetailViewController {
            let trainingExerciseViewController = viewControllers?[0] as? TrainingExerciseViewController
            exerciseDetailViewController.exercise = trainingExerciseViewController?.trainingExercise?.exercise
        }
    }

}

extension TrainingExercisePageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let trainingExercise = (viewController as! TrainingExerciseViewController).trainingExercise, let trainingExercises = trainingExercise.training?.trainingExercises {
            let newIndex = trainingExercises.index(of: trainingExercise) - 1
            if newIndex >= 0 {
                return instantiateTrainingExerciseViewController(with: trainingExercises[newIndex] as! TrainingExercise)
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let trainingExercise = (viewController as! TrainingExerciseViewController).trainingExercise, let trainingExercises = trainingExercise.training?.trainingExercises {
            let newIndex = trainingExercises.index(of: trainingExercise) + 1
            if newIndex < trainingExercises.count {
                return instantiateTrainingExerciseViewController(with: trainingExercises[newIndex] as! TrainingExercise)
            }
        }
        return nil
    }
}

extension TrainingExercisePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let newViewController = pageViewController.viewControllers?[0] {
            title = newViewController.title
            isEditing = newViewController.isEditing
        }
    }
}
