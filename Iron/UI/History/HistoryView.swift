//
//  HistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct HistoryView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(fetchRequest: HistoryView.fetchRequest) var workouts

    static var fetchRequest: NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }
    
    @State private var offsetsToDelete: IndexSet?
    
    private func deleteAtOffsets(offsets: IndexSet) {
        let workouts = self.workouts
        for i in offsets.sorted().reversed() {
            self.managedObjectContext.delete(workouts[i])
        }
        self.managedObjectContext.safeSave()
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(workouts, id: \.objectID) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)
                        .environmentObject(self.settingsStore)
                    ) {
                        WorkoutCell(workout: workout)
                            .contextMenu {
                                // TODO add images when SwiftUI fixes the image size
                                Button("Share") {
                                    WorkoutDetailView.shareWorkout(workout: workout, in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit)
                                }
                                Button("Repeat") {
                                    WorkoutDetailView.repeatWorkout(workout: workout, settingsStore: self.settingsStore)
                                }
                                Button("Repeat (Blank)") {
                                    WorkoutDetailView.repeatWorkoutBlank(workout: workout, settingsStore: self.settingsStore)
                                }
                            }
                    }
                }
                .onDelete { offsets in
                    guard UIDevice.current.userInterfaceIdiom != .pad else { // TODO: actionSheet not supported on iPad yet (13.2)
                        self.deleteAtOffsets(offsets: offsets)
                        return
                    }
                    self.offsetsToDelete = offsets
                }
            }
            .navigationBarItems(trailing: EditButton())
            .actionSheet(item: $offsetsToDelete) { offsets in
                ActionSheet(title: Text("This cannot be undone."), buttons: [
                    .destructive(Text("Delete Workout"), action: {
                        self.deleteAtOffsets(offsets: offsets)
                    }),
                    .cancel()
                ])
            }
            .placeholder(show: workouts.isEmpty,
                         Text("Your finished workouts will appear here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
            )
            .navigationBarTitle(Text("History"))
        }
        .navigationViewStyle(StackNavigationViewStyle()) // TODO: remove, currently needed for iPad as of 13.1.1
    }
}

private struct WorkoutCell: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject var workout: Workout

    private var durationString: String? {
        guard let duration = workout.duration else { return nil }
        return Workout.durationFormatter.string(from: duration)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(workout.displayTitle(in: self.exerciseStore.exercises))
                    .font(.body)
                
                Text(Workout.dateFormatter.string(from: workout.start, fallback: "Unknown date"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                workout.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            .layoutPriority(1)
            
            Spacer()
            
            durationString.map {
                Text($0)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(Color(.systemFill))
                        
                )
            }
            
            workout.muscleGroupImage(in: self.exerciseStore.exercises)
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
