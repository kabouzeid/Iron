//
//  ActivityWorkoutsPerWeekCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityWorkoutsPerWeekCell : View {
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    private var chartView: some View {
        Group {
            if entitlementStore.isPro {
                ActivityWorkoutsPerWeekView()
            } else {
                ActivityDemoChartView().overlay(UnlockProOverlay())
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding([.top, .bottom], 5)
            
            Text("Workouts Per Week" + (entitlementStore.isPro ? "" : " (Demo Data)"))
                .font(.headline)
                .padding([.top, .bottom], 3)
            
            Divider()
                .padding([.top, .bottom], 3)
            
            chartView
                .frame(height: 250)
                .padding([.top, .bottom], 8)
        }
    }
}

#if DEBUG
struct ActivityWorkoutsPerWeekViewCell_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ActivityWorkoutsPerWeekCell()
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivityWorkoutsPerWeekCell()
                    .mockEnvironment(weightUnit: .metric, isPro: true)
                    .previewLayout(.sizeThatFits)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
