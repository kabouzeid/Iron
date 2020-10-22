//
//  ActivityCalendarViewCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityCalendarViewCell: View {
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            Text("Workouts Last 28 Days")
                .font(.headline)
            
            Divider()
            
            ActivityCalendarHeaderView()
                .padding([.top, .bottom], 4)
            
            Divider()
            
            ActivityCalendarView()
                .frame(height: 250)
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct ActivityCalendarViewCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityCalendarViewCell()
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivityCalendarViewCell()
                    .mockEnvironment(weightUnit: .metric, isPro: true)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
