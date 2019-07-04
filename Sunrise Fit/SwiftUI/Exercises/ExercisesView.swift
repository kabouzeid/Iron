//
//  ExercisesView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 04.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExercisesView : View {
    var exercises: [Exercise]
    
    var body: some View {
        List(exercises.identified(by: \.id)) { exercise in
            NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise))
        }
    }
}

#if DEBUG
struct ExercisesView_Previews : PreviewProvider {
    static var previews: some View {
        ExercisesView(exercises: EverkineticDataProvider.exercises)
    }
}
#endif
