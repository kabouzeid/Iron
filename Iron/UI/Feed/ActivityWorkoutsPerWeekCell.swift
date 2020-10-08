//
//  ActivityWorkoutsPerWeekCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivityWorkoutsPerWeekCell : View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            Text("Workouts Per Week")
                .font(.headline)
            
            Divider()
            
            ActivityWorkoutsPerWeekView()
                .frame(height: 200)
        }
        .padding([.top, .bottom], 8)
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
