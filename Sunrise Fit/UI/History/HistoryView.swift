//
//  HistoryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct HistoryView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    
    private var fetchRequest: NSFetchRequest<Training> {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentTraining != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        return request
    }
    
    private var trainings: [Training] {
        return (try? trainingsDataStore.context.fetch(fetchRequest)) ?? []
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(trainings, id: \.objectID) { training in
                    NavigationLink(destination: TrainingDetailView(training: training)
                        .environmentObject(self.trainingsDataStore)
                        .environmentObject(self.settingsStore)
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(training.displayTitle)
                                    .font(.body)
                                Text("\(Training.dateFormatter.string(from: training.start!)) for \(Training.durationFormatter.string(from: training.duration)!)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .layoutPriority(1)
                            Spacer()
                            training.muscleGroupImage
                        }
                    }
                }
                .onDelete { offsets in
                    // TODO: confirm delete
                    let trainings = self.trainings
                    for index in offsets {
                        self.trainingsDataStore.context.delete(trainings[index])
                    }
                }
            }
            .navigationBarTitle(Text("History"))
            .navigationBarItems(trailing: EditButton())
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
