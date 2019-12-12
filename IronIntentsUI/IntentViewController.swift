//
//  IntentViewController.swift
//  IronIntentsUI
//
//  Created by Karim Abou Zeid on 07.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import IntentsUI
import SwiftUI
import WorkoutDataKit

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        // Do configuration here, including preparing views and calculating a desired size for presentation.
        if let response = interaction.intentResponse as? ViewOneRepMaxIntentResponse {
            guard let setIdentifier = response.set?.identifier,
                let objectIdURI = URL(string: setIdentifier),
                let objectId = WorkoutDataStorage.shared.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectIdURI),
                let set = try? WorkoutDataStorage.shared.persistentContainer.viewContext.existingObject(with: objectId) as? WorkoutSet else {
                    completion(false, parameters, .zero)
                    return
            }
            
            guard let exerciseUuid = set.workoutExercise?.exerciseUuid,
                let exercise = ExerciseStore.shared.find(with: exerciseUuid) else {
                    completion(false, parameters, .zero)
                    return
            }
            
            guard let highlightDate = set.workoutExercise?.workout?.start else {
                completion(false, parameters, .zero)
                return
            }
            
            print(highlightDate)
            
            attachChild(UIHostingController(rootView:
                OneRepMaxView(exercise: exercise, highlightDate: highlightDate)
                    .environment(\.managedObjectContext, WorkoutDataStorage.shared.persistentContainer.viewContext)
                    .environmentObject(SettingsStore.shared)
                    .environmentObject(EntitlementStore.shared)
                    .accentColor(.blue)
                    .padding()
            ))
            completion(true, parameters, .init(width: desiredSize.width, height: 300))
            return
        } else if let response = interaction.intentResponse as? ViewPersonalRecordsIntentResponse {
            guard let intentSet = response.set else {
                    completion(false, parameters, .zero)
                    return
            }
            
            attachChild(UIHostingController(rootView:
                PersonalRecordView(displayString: intentSet.displayString)
                    .accentColor(.blue)
//                    .padding()
            ))
            completion(true, parameters, .init(width: desiredSize.width, height: 150))
        }
        
        completion(false, parameters, .zero)
    }
    
    var desiredSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
    private func attachChild(_ viewController: UIViewController) {
        addChild(viewController)
        
        if let subview = viewController.view {
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false

            // Set the child controller's view to be the exact same size as the parent controller's view.
            subview.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            subview.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

            subview.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            subview.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        
        viewController.didMove(toParent: self)
    }
}
