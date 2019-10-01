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
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    func exerciseGroupCell(exercises: [Exercise]) -> some View {
        let muscleGroup = exercises.first?.muscleGroup ?? ""
        return NavigationLink(destination:
            ExercisesView(exercises: exercises)
                .listStyle(PlainListStyle())
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
    
    private var exercisesGrouped: [[Exercise]] {
        ExerciseStore.splitIntoMuscleGroups(exercises: exerciseStore.exercises)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination:
                        MuscleGroupSectionedExercisesView(exerciseMuscleGroups: exercisesGrouped)
                            .environmentObject(settingsStore)
                            .navigationBarTitle(Text("All Exercises"), displayMode: .inline)) {
                        HStack {
                            Text("All")
                            Spacer()
                            Text("(\(exerciseStore.exercises.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    ForEach(exercisesGrouped, id: \.first?.muscleGroup) { exerciseGroup in
                       self.exerciseGroupCell(exercises: exerciseGroup)
                    }
                }
                
                Section {
                    NavigationLink(destination:
                        CustomExercisesView()
                            .navigationBarTitle(Text("Custom"), displayMode: .inline)
                    ) {
                        HStack {
                            Text("Custom")
                            Spacer()
                            Text("(\(exerciseStore.customExercises.count))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Exercises")
        }
        .navigationViewStyle(StackNavigationViewStyle()) // TODO: remove, currently needed for iPad as of 13.1.1
    }
}

#if DEBUG
struct ExerciseCategoryView_Previews : PreviewProvider {
    static var previews: some View {
        ExerciseMuscleGroupsView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
