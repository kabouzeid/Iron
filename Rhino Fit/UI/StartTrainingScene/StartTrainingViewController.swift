//
//  StartTrainingViewController.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 28.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

class StartTrainingViewController: UIViewController, UITabBarControllerDelegate {

    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.layer.cornerRadius = 8
        tabBarController?.delegate = self
    }

    // MARK: - Navigation
    
    @IBAction func comeBackToStartTraining(segue: UIStoryboardSegue) {}
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let id = segue.identifier {
            switch (id) {
            case "start new training":
                segue.destination.wrappedViewController().navigationItem.title = "Training"
            case "continue with plan":
                segue.destination.wrappedViewController().navigationItem.title = "Stronglifts (Example)"
            default:
                break
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != navigationController || tabBarController.selectedViewController != navigationController // disable double tap tabbar for this tab only
    }
}
