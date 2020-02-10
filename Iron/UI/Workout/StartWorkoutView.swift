//
//  StartWorkoutView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct StartWorkoutView: View {
    @State private var quote = Quotes.quotes.randomElement()
    
    @FetchRequest(fetchRequest: StartWorkoutView.fetchRequest) var workoutPlans

    static var fetchRequest: NSFetchRequest<WorkoutPlan> {
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutPlan.title, ascending: false)]
        return request
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    StartEmptyWorkoutCell()
                }
                
                ForEach(workoutPlans, id: \.objectID) { workoutPlan in
                    Section {
                        WorkoutPlanCell(workoutPlan: workoutPlan)
                        WorkoutPlanRoutines(workoutPlan: workoutPlan)
                    }
                }
                
                Section {
                    Button(action: {
                        #warning("TODO create plan sheet")
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Workout Plan")
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Workout")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct StartEmptyWorkoutCell: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @EnvironmentObject var settingsStore: SettingsStore
    
    let quote: Quote? = Quotes.quotes[4]
    
    private var plateImage: some View {
        Image(settingsStore.weightUnit == .imperial ? "plate_lbs" : "plate_kg")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .frame(maxWidth: 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                if colorScheme == .dark {
                    plateImage.colorInvert()
                } else {
                    plateImage
                }
            }
            
            quote.map {
                Text($0.displayText)
                     .multilineTextAlignment(.center)
                     .foregroundColor(.secondary)
            }
            
            Button(action: {
                precondition((try? self.managedObjectContext.count(for: Workout.currentWorkoutFetchRequest)) ?? 0 == 0)
                // create a new workout
                let workout = Workout(context: self.managedObjectContext)
                workout.uuid = UUID()
                
                workout.start(alsoStartOnWatch: self.settingsStore.watchCompanion)
            }) {
                HStack {
                    Spacer()
                    Text("Start Workout")
                    Spacer()
                }
                .padding()
                .foregroundColor(.accentColor)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).foregroundColor(Color(.systemFill)))
            }.buttonStyle(BorderlessButtonStyle())
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct WorkoutPlanCell: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    
    var body: some View {
        NavigationLink(destination: WorkoutPlanView(workoutPlan: workoutPlan)) {
            VStack(alignment: .leading) {
                Text(workoutPlan.title ?? "").font(.headline)
            }
            .contextMenu {
                Button(action: {
                    _ = self.workoutPlan.duplicate(context: self.managedObjectContext)
                }) {
                    Text("Duplicate")
                    Image(systemName: "doc.on.doc")
                }
                Button(action: {
                    self.managedObjectContext.delete(self.workoutPlan)
                }) {
                    Text("Delete")
                    Image(systemName: "trash")
                }
            }
        }
    }
}

private struct WorkoutPlanRoutines: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var workoutPlan: WorkoutPlan
    
    private var workoutRoutines: [WorkoutRoutine] {
        workoutPlan.workoutRoutines?.array as? [WorkoutRoutine] ?? []
    }
    
    private func workoutRoutineExercises(workoutRoutine: WorkoutRoutine) -> [WorkoutRoutineExercise] {
        workoutRoutine.workoutRoutineExercises?.array as? [WorkoutRoutineExercise] ?? []
    }
    
    private func workoutRoutineExercisesString(workoutRoutine: WorkoutRoutine) -> String {
        workoutRoutineExercises(workoutRoutine: workoutRoutine)
            .compactMap { $0.exercise(in: self.exerciseStore.exercises)?.title }
            .joined(separator: ", ")
    }
    
    var body: some View {
        ForEach(workoutRoutines, id: \.objectID) { workoutRoutine in
            Button(action: {
                precondition((try? self.managedObjectContext.count(for: Workout.currentWorkoutFetchRequest)) ?? 0 == 0)
                // create the workout
                let workout = workoutRoutine.createWorkout(context: self.managedObjectContext)
                
                workout.start(alsoStartOnWatch: self.settingsStore.watchCompanion)
            }) {
                VStack(alignment: .leading) {
                    Text(workoutRoutine.title ?? "").italic()
                    Text(self.workoutRoutineExercisesString(workoutRoutine: workoutRoutine))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

#if DEBUG
struct StartWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartWorkoutView()
            
            StartWorkoutView()
                .environment(\.colorScheme, .dark)
            
            StartWorkoutView()
                .previewDevice(.init("iPhone SE"))
            
            StartWorkoutView()
                .previewDevice(.init("iPhone 11 Pro Max"))
        }
        .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
