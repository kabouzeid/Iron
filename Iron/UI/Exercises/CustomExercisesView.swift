//
//  CustomExercisesView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct CustomExercisesView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var entitlementStore: EntitlementStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @State private var showCreateCustomExerciseSheet = false
    
    @State private var offsetsToDelete: IndexSet?
    
    var body: some View {
        List {
            ForEach(exerciseStore.customExercises, id: \.id) { exercise in
                NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise)
                    .environmentObject(self.settingsStore))
            }
            .onDelete { offsets in
                self.offsetsToDelete = offsets
            }
            Button(action: {
                self.showCreateCustomExerciseSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Exercise")
                }
            }.disabled(!entitlementStore.isPro)
        }
        .listStyle(GroupedListStyle())
        .navigationBarItems(trailing: EditButton())
        .sheet(isPresented: $showCreateCustomExerciseSheet) {
            CreateCustomExerciseSheet()
                .environmentObject(self.exerciseStore)
        }
        .actionSheet(item: $offsetsToDelete) { offsets in
            // TODO: in future only show this warning when there are in fact sets that will be deleted
            ActionSheet(title: Text("This cannot be undone."), message: Text("Warning: Any set belonging to this exercise will be deleted too."), buttons: [
                .destructive(Text("Delete"), action: {
                    for i in offsets {
                        assert(self.exerciseStore.customExercises[i].isCustom)
                        let id = self.exerciseStore.customExercises[i].id
                        self.deleteTrainingExercises(with: id)
                        self.exerciseStore.deleteCustomExercise(with: id)
                    }
                    self.managedObjectContext.safeSave()
                }),
                .cancel()
            ])
        }
    }
    
    private func deleteTrainingExercises(with id: Int) {
        let request: NSFetchRequest<TrainingExercise> = TrainingExercise.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(TrainingExercise.exerciseId)) == %@", NSNumber(value: id))
        guard let trainingExercises = try? managedObjectContext.fetch(request) else { return }
        trainingExercises.forEach { managedObjectContext.delete($0) }
    }
}

#if DEBUG
struct CustomExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomExercisesView()
            .environmentObject(SettingsStore.shared)
            .environmentObject(ExerciseStore.shared)
            .environmentObject(EntitlementStore.mockPro)
    }
}
#endif
