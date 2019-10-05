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
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case createCustomExercise
        case buyPro
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .createCustomExercise:
            return CreateCustomExerciseSheet()
                .environmentObject(exerciseStore)
                .typeErased
        case .buyPro:
            return PurchaseSheet()
                .environmentObject(entitlementStore)
                .typeErased
        }
    }
    
    @State private var offsetsToDelete: IndexSet?
    
    private func deleteAtOffsets(offsets: IndexSet) {
        for i in offsets {
            assert(self.exerciseStore.customExercises[i].isCustom)
            let id = self.exerciseStore.customExercises[i].id
            self.deleteWorkoutExercises(with: id)
            self.exerciseStore.deleteCustomExercise(with: id)
        }
        self.managedObjectContext.safeSave()
    }
    
    var body: some View {
        List {
            ForEach(exerciseStore.customExercises, id: \.id) { exercise in
                NavigationLink(exercise.title, destination: ExerciseDetailView(exercise: exercise)
                    .environmentObject(self.settingsStore))
            }
            .onDelete { offsets in
                guard UIDevice.current.userInterfaceIdiom != .pad else { // TODO: actionSheet not supported on iPad yet (13.2)
                    self.deleteAtOffsets(offsets: offsets)
                    return
                }
                self.offsetsToDelete = offsets
            }
            Button(action: {
                self.activeSheet = self.entitlementStore.isPro ? .createCustomExercise : .buyPro
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Exercise")
                    if !entitlementStore.isPro {
                        Spacer()
                        Group {
                            Text("Iron Pro")
                            Image(systemName: "lock")
                        }.foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarItems(trailing: EditButton())
        .sheet(item: $activeSheet, content: { type in
            self.sheetView(type: type)
        })
        .actionSheet(item: $offsetsToDelete) { offsets in
            // TODO: in future only show this warning when there are in fact sets that will be deleted
            ActionSheet(title: Text("This cannot be undone."), message: Text("Warning: Any set belonging to this exercise will be deleted too."), buttons: [
                .destructive(Text("Delete"), action: {
                    self.deleteAtOffsets(offsets: offsets)
                }),
                .cancel()
            ])
        }
    }
    
    private func deleteWorkoutExercises(with id: Int) {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.exerciseId)) == %@", NSNumber(value: id))
        guard let workoutExercises = try? managedObjectContext.fetch(request) else { return }
        workoutExercises.forEach { managedObjectContext.delete($0) }
    }
}

#if DEBUG
struct CustomExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomExercisesView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
