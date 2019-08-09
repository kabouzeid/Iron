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
    var exerciseMuscleGroups: [[Exercise]]
    
    func exerciseGroupCell(exercises: [Exercise]) -> some View {
        let muscleGroup = exercises.first?.muscleGroup ?? ""
        return NavigationLink(destination:
            ExercisesView(exercises: exercises)
                .listStyle(PlainListStyle())
                .environmentObject(self.settingsStore)
                .navigationBarTitle(Text(muscleGroup.capitalized), displayMode: .inline)
        ) {
            HStack {
                Text(muscleGroup.capitalized)
                Spacer()
                Text("(\(exercises.count))")
                    .foregroundColor(.secondary)
                Exercise.imageFor(muscleGroup: muscleGroup)
                    .foregroundColor(Exercise.colorFor(muscleGroup: muscleGroup))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination:
                        MuscleGroupSectionedExercisesView(exerciseMuscleGroups: exerciseMuscleGroups)
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
                       self.exerciseGroupCell(exercises: exerciseGroup)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Exercises")
        }
    }
}

#if DEBUG
struct ExerciseCategoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseMuscleGroupsView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped)
            .environmentObject(mockSettingsStoreMetric)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
