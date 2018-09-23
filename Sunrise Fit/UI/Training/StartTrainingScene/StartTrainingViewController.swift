//
//  StartTrainingViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 28.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class StartTrainingViewController: UIViewController, UITabBarControllerDelegate {
    
    let persistentContainer = AppDelegate.instance.persistentContainer

    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.layer.cornerRadius = 8
        tabBarController?.delegate = self
        
        if Training.fetchCurrentTraining(context: persistentContainer.viewContext) != nil {
            performSegue(withIdentifier: "continue last training", sender: self)
        }
    }

    // MARK: - Navigation
    
    @IBAction func comeBackToStartTraining(segue: UIStoryboardSegue) {}
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let id = segue.identifier {
            switch (id) {
            case "continue last training":
                if let trainingViewController = segue.destination as? CurrentTrainingViewController,
                    let training = Training.fetchCurrentTraining(context: persistentContainer.viewContext) {
                    trainingViewController.training = training
                }
            case "start new training":
                if let trainingViewController = segue.destination as? CurrentTrainingViewController {
                    Training.deleteCurrentTraining(context: persistentContainer.viewContext) // just to be sure

                    let training = Training(context: persistentContainer.viewContext)
                    training.isCurrentTraining = true

                    trainingViewController.training = training
                }
            case "continue with plan":
                if let trainingViewController = segue.destination.wrappedViewController() as? CurrentTrainingViewController {
                    Training.deleteCurrentTraining(context: persistentContainer.viewContext) // just to be sure

                    // TODO actually get the training from the current plan
                    let training = Training(context: persistentContainer.viewContext)
                    training.isCurrentTraining = true
                    training.title = "StrongLifts 5x5" // Stub, for testing only

                    trainingViewController.training = training
                }
            default:
                break
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // disable double tap on tab for this tab
        return viewController != navigationController || tabBarController.selectedViewController != navigationController
    }
}
