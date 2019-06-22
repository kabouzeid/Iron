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
            List(trainings.identified(by: \.objectID)) { training in
                VStack(alignment: .leading) {
                    Text(training.displayTitle)
                        .font(.body)
                    Text("\(Training.dateFormatter.string(from: training.start!)) for \(Training.durationFormatter.string(from: training.duration)!)")
                        .font(.caption)
                        .color(.secondary)
                }
            }
            .navigationBarTitle(Text("History"))
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
#endif
