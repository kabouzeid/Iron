//
//  ExerciseCategoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseMuscleGroupsView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore // TODO: (bug in beta3?) remove in future, only needed for the presentation of the statistics view
    var exerciseMuscleGroups: [[Exercise]]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination:
                        MuscleGroupSectionedExercisesView(exerciseMuscleGroups: exerciseMuscleGroups)
                            .environmentObject(trainingsDataStore)
                            .environmentObject(settingsStore)
                            .navigationBarTitle(Text("All Exercises"), displayMode: .inline)) {
                        HStack {
                            Text("All")
                            Spacer()
                            Text("(\(exerciseMuscleGroups.flatMap { $0 }.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section {
                    ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exerciseGroup in
                        NavigationLink(destination:
                            ExercisesView(exercises: exerciseGroup)
                                .environmentObject(self.trainingsDataStore)
                                .environmentObject(self.settingsStore)
                                .navigationBarTitle(Text(exerciseGroup.first?.muscleGroup.capitalized ?? ""), displayMode: .inline)) {
                            HStack {
                                Text(exerciseGroup.first?.muscleGroup.capitalized ?? "")
                                Spacer()
                                Text("(\(exerciseGroup.count))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationBarTitle("Exercises")
        }
    }
}

#if DEBUG
struct ExerciseCategoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseMuscleGroupsView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
