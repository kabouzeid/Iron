//
//  HealthSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 31.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct HealthSettingsView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var updating = false
    @State private var updateResult: IdentifiableHolder<Result<HealthManager.WorkoutUpdates, Error>>?
    
    func updateResultAlert(updateResult: Result<HealthManager.WorkoutUpdates, Error>) -> Alert {
        switch updateResult {
        case .success(let updates):
            return Alert(
                title: Text("Successfully Updated Workouts in Apple Health"),
                message: Text("\(updates.created) workouts were created, \(updates.deleted) workouts were deleted and \(updates.modified) workouts were modified.")
            )
        case .failure(let error):
            return Alert(title: Text("Update Workouts in Apple Health Failed"), message: Text(error.localizedDescription))
        }
    }
    
    var body: some View {
        Form {
            Section(footer: Text("Adds missing workouts to Apple Health and removes workouts from Apple Health that are no longer present in Iron. This also updates workouts where the start or end time has been modified.")) {
                Button("Update Apple Health Workouts") {
                    self.updating = true
                    HealthManager.shared.updateHealthWorkouts(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore) { result in
                        DispatchQueue.main.async {
                            self.updateResult = IdentifiableHolder(value: result)
                            self.updating = false
                        }
                    }
                }
                .disabled(updating) // wait for updating to finish before allowing to tap again
            }
        }
        .navigationBarTitle("Apple Health", displayMode: .inline)
        .alert(item: $updateResult) { updateResultHolder in
            self.updateResultAlert(updateResult: updateResultHolder.value)
        }
    }
}

import HealthKit
extension HealthSettingsView {
    static var isSupported: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
}

struct HealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthSettingsView()
    }
}
