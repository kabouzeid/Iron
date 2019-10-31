//
//  HealthSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 31.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct HealthSettingsView: View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State private var updateResult: IdentifiableHolder<Result<Void, Error>>?
    
    func updateResultAlert(updateResult: Result<Void, Error>) -> Alert {
        switch updateResult {
        case .success():
            return Alert(title: Text("Successfully Updated Workouts in Apple Health"))
        case .failure(let error):
            return Alert(title: Text("Update Workouts in Apple Health Failed"), message: Text(error.localizedDescription))
        }
    }
    
    var body: some View {
        Form {
            Section(footer: Text("Adds missing workouts to Apple Health and removes workouts from Apple Health that are no longer present in Iron.")) {
                Button("Update Apple Health Workouts") {
                    HealthManager.shared.updateHealthWorkouts(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore) { result in
                        DispatchQueue.main.async {
                            self.updateResult = IdentifiableHolder(value: result)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Apple Health", displayMode: .inline)
        .alert(item: $updateResult) { updateResultHolder in
            self.updateResultAlert(updateResult: updateResultHolder.value)
        }
    }
}

struct HealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthSettingsView()
    }
}
