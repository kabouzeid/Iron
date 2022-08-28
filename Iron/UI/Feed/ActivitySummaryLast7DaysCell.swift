//
//  ActivityLast7DaysCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ActivitySummaryLast7DaysCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            Text("Summary Last 7 Days")
                .font(.headline)
            
            Divider()
            
            ActivitySummaryLast7DaysView()
        }
        .padding([.top, .bottom], 8)
    }
}

#if DEBUG
struct ActivityLast7DaysCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivitySummaryLast7DaysCell()
                .mockEnvironment(weightUnit: .metric)
                .previewLayout(.sizeThatFits)
            
            List {
                ActivitySummaryLast7DaysCell()
                    .mockEnvironment(weightUnit: .metric)
            }.listStyleCompat_InsetGroupedListStyle()
        }
    }
}
#endif
