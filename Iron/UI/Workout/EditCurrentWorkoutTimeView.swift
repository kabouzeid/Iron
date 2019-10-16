//
//  EditCurrentWorkoutTimeView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 14.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct EditCurrentWorkoutTimeView: View {
    @ObservedObject var workout: Workout
    
    var automaticTimeTracking: Binding<Bool> {
        Binding(
            get: {
                self.workout.end == nil
            },
            set: { enabled in
                if enabled {
                    precondition(self.workout.isCurrentWorkout)
                    self.workout.end = nil
                } else {
                    self.workout.end = self.workout.safeEnd
                }
            }
        )
    }

    var body: some View {
        List {
            Section {
                DatePicker(selection: $workout.safeStart, in: ...min(workout.safeEnd, Date())) {
                    Text("Start")
                }
                
                Toggle("Automatic Time Tracking", isOn: automaticTimeTracking)

                if !automaticTimeTracking.wrappedValue {
                    DatePicker(selection: $workout.safeEnd, in: workout.safeStart...Date()) {
                        Text("End")
                    }
                }
            }
            
            Section {
                Button("Reset Start Time") {
                    let newStart = Date()
                    if let end = self.workout.end, end < newStart {
                        self.workout.end = newStart
                    }
                    self.workout.start = newStart
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct EditCurrentWorkoutTimeView_Previews: PreviewProvider {
    static var previews: some View {
        EditCurrentWorkoutTimeView(workout: MockWorkoutData.metricRandom.currentWorkout)
    }
}
#endif
