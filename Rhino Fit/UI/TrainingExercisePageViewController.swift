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
        }
    }
//    private var persistentContainer: NSPersistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
    
}
