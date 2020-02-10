//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import StoreKit
import MessageUI

struct SettingsView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    private var ironProSection: some View {
        Section {
            NavigationLink(destination: PurchaseView()) {
                Text("Iron Pro")
            }
        }
    }
    
    private var mainSection: some View {
        Section {
            NavigationLink(destination: GeneralSettingsView()) {
                Text("General")
            }
            
            NavigationLink(destination: HealthSettingsView()) {
                Text("Apple Health")
            }
            
            NavigationLink(destination: WatchSettingsView()) {
                Text("Apple Watch")
            }
            
            NavigationLink(destination: BackupAndExportView()) {
                Text("Backup & Export")
            }
        }
    }
    
    @State private var showSupportMailAlert = false // if mail client is not configured
    private var ratingAndSupportSection: some View {
        Section {
            Button(action: {
                guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1479893244?action=write-review") else { return }
                UIApplication.shared.open(writeReviewURL)
            }) {
                HStack {
                    Text("Rate Iron")
                    Spacer()
                    Image(systemName: "star")
                }
            }
            
            Button(action: {
                guard MFMailComposeViewController.canSendMail() else {
                    self.showSupportMailAlert = true // fallback
                    return
                }
                
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = MailCloseDelegate.shared
                mail.setToRecipients(["support@ironapp.io"])
                
                // TODO: replace this hack with a proper way to retreive the rootViewController
                guard let rootVC = UIApplication.shared.activeSceneKeyWindow?.rootViewController else { return }
                rootVC.present(mail, animated: true)
            }) {
                HStack {
                    Text("Send Feedback")
                    Spacer()
                    Image(systemName: "paperplane")
                }
            }
            .alert(isPresented: $showSupportMailAlert) {
                Alert(title: Text("Support E-Mail"), message: Text("support@ironapp.io"))
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                ironProSection
                
                mainSection
                
                ratingAndSupportSection
                
                #if DEBUG
                Button("Create default workout plans") {
                    createDefaultWorkoutPlans()
                }
                #endif
            }
            .navigationBarTitle(Text("Settings"))
        }
        .navigationViewStyle(StackNavigationViewStyle()) // TODO: remove, currently needed for iPad as of 13.1.1
    }
}

#if DEBUG
import WorkoutDataKit
func toUuid(_ id: Int) -> UUID? {
    ExerciseStore.shared.exercises.first { $0.everkineticId == id }?.uuid
}

func niceWeight(weight: Double, unit: WeightUnit) -> Double {
    let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
    let nice = weightInUnit - weightInUnit.truncatingRemainder(dividingBy: unit.barbellIncrement)
    return WeightUnit.convert(weight: nice, from: unit, to: .metric)
}

func createDefaultWorkoutPlans() {
    let context = WorkoutDataStorage.shared.persistentContainer.viewContext
    let unit = SettingsStore.shared.weightUnit
    
    let create5x5 = { (weight: Double) -> [WorkoutRoutineSet] in
        (0..<5).map { _ -> WorkoutRoutineSet in
            let set = WorkoutRoutineSet(context: context)
            set.repetitions = 5
            set.weight = weight
            return set
        }
    }
    
    let workoutRoutineExerciseSquatA = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseSquatA.exerciseUuid = toUuid(122) // squat
    workoutRoutineExerciseSquatA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))
    
    let workoutRoutineExerciseBenchA = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseBenchA.exerciseUuid = toUuid(42) // bench
    workoutRoutineExerciseBenchA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 80, unit: unit)))
    
    let workoutRoutineExerciseRowA = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseRowA.exerciseUuid = toUuid(298) // row
    workoutRoutineExerciseRowA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 60, unit: unit)))
    
    let workoutRoutineA = WorkoutRoutine(context: context)
    workoutRoutineA.title = "Workout A"
    workoutRoutineA.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatA, workoutRoutineExerciseBenchA, workoutRoutineExerciseRowA)
    
    let workoutRoutineExerciseSquatB = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseSquatB.exerciseUuid = toUuid(122) // squat
    workoutRoutineExerciseSquatB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))
    
    let workoutRoutineExerciseBenchB = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseBenchB.exerciseUuid = toUuid(9001) // press
    workoutRoutineExerciseBenchB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 65, unit: unit)))
    
    let workoutRoutineExerciseRowB = WorkoutRoutineExercise(context: context)
    workoutRoutineExerciseRowB.exerciseUuid = toUuid(99) // deadlift
    workoutRoutineExerciseRowB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 140, unit: unit)))
    
    let workoutRoutineB = WorkoutRoutine(context: context)
    workoutRoutineB.title = "Workout B"
    workoutRoutineB.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatB, workoutRoutineExerciseBenchB, workoutRoutineExerciseRowB)
    
    let workoutPlan = WorkoutPlan(context: context)
    workoutPlan.title = "StrongLifts 5x5"
    workoutPlan.workoutRoutines = NSOrderedSet(arrayLiteral: workoutRoutineA, workoutRoutineB)
}
#endif

// hack because we can't store it in the View
private class MailCloseDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailCloseDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
