//
//  WorkoutDetailBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutDetailBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject var workout: Workout
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()

        entries.append(BannerViewEntry(id: 0, title: Text("Duration"), text: Text(Workout.durationFormatter.string(from: workout.safeDuration) ?? "")))
        entries.append(BannerViewEntry(id: 1, title: Text("Sets"), text: Text(String(workout.numberOfCompletedSets ?? 0))))
        entries.append(BannerViewEntry(id: 2, title: Text("Weight"), text: Text(WeightUnit.format(weight: workout.totalCompletedWeight ?? 0, from: .metric, to: settingsStore.weightUnit))))
        return entries
    }
}

#if DEBUG
struct WorkoutDetailSummaryView_Previews : PreviewProvider {
    static var previews: some View {
        WorkoutDetailBannerView(workout: MockWorkoutData.metricRandom.workout)
            .mockEnvironment(weightUnit: .metric)
            .previewLayout(.sizeThatFits)
    }
}
#endif
