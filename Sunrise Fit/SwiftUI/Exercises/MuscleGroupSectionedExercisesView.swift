//
//  MuscleGroupSectionedExercisesView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct MuscleGroupSectionedExercisesView : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore // TODO: (bug in beta3?) remove in future, only needed for the presentation of the statistics view
    var exerciseMuscleGroups: [[Exercise]]
    
    var body: some View {
        List {
            ForEach(exerciseMuscleGroups.identified(by: \.first?.muscleGroup)) { exercises in
                Section(header: Text(exercises.first?.muscleGroup.capitalized ?? "")) {
                    ForEach(exercises.identified(by: \.id)) { exercise in
                        NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise).environmentObject(self.trainingsDataStore))
                    }
                }
            }
        }
    }
}

#if DEBUG
struct MuscleGroupSectionedExercisesView_Previews : PreviewProvider {
    static var previews: some View {
        MuscleGroupSectionedExercisesView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped)
    }
}
#endif