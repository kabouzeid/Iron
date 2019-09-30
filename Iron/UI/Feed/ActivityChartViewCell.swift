//
//  ActivityChartViewCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityChartViewCell : View {
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    private var chartView: some View {
        Group {
            if entitlementStore.isPro {
                ActivityChartView()
            } else {
                ActivityDemoChartView().overlay(UnlockProOverlay())
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Activity")
                .font(.body)
            Text("Workouts per week" + (entitlementStore.isPro ? "" : " (Demo data)"))
                .font(.caption)
                .foregroundColor(.secondary)
            chartView
                .frame(height: 250)
        }
    }
}

#if DEBUG
struct ActivityChartViewCell_Previews : PreviewProvider {
    static var previews: some View {
        ActivityChartViewCell()
            .environment(\.managedObjectContext, mockManagedObjectContext)
            .environmentObject(ExerciseStore.shared)
            .environmentObject(EntitlementStore.mockNoPro)
            .previewLayout(.sizeThatFits)
    }
}
#endif
