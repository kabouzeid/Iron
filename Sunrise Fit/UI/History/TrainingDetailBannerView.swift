//
//  TrainingDetailBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingDetailBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    let training: Training
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()

        entries.append(BannerViewEntry(id: 0, title: Text("Duration"), text: Text(Training.durationFormatter.string(from: training.duration) ?? "")))
        entries.append(BannerViewEntry(id: 1, title: Text("Sets"), text: Text(String(training.numberOfCompletedSets ?? 0))))
        entries.append(BannerViewEntry(id: 2, title: Text("Weight"), text: Text("\(TrainingSet.weightStringFor(weightInKg: training.totalCompletedWeight ?? 0, unit: settingsStore.weightUnit))")))
        return entries
    }
}

#if DEBUG
struct TrainingDetailSummaryView_Previews : PreviewProvider {
    static var previews: some View {
        TrainingDetailBannerView(training: mockTraining)
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
            .previewLayout(.sizeThatFits)
    }
}
#endif