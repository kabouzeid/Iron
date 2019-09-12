//
//  TrainingTab.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingTab: View {
    @FetchRequest(fetchRequest: Training.currentTrainingFetchRequest) var currentTrainings
    
    var currentTraining: Training? {
        assert(currentTrainings.count <= 1)
        return currentTrainings.first
    }
    
    private func trainingView(training: Training?) -> some View {
        Group { // is Group the appropiate choice here? (want to avoid AnyView)
            if training != nil {
                TrainingView(training: training!)
            } else {
                StartTrainingView()
            }
        }
    }
    
    var body: some View {
        trainingView(training: currentTraining)
    }
}

#if DEBUG
struct TrainingTab_Previews: PreviewProvider {
    static var previews: some View {
        TrainingTab()
            .environmentObject(mockSettingsStoreMetric)
            .environmentObject(restTimerStore)
            .environment(\.managedObjectContext, mockManagedObjectContext)
    }
}
#endif
