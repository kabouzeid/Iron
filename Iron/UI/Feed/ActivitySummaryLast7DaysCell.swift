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
        VStack(alignment: .leading, spacing: 0) {
            Text("Activity")
                .bold()
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding([.top, .bottom], 5)
            
            Text("Summary Last 7 Days")
                .font(.headline)
                .padding([.top, .bottom], 3)
            
            Divider()
                .padding([.top, .bottom], 3)
            
            FeedBannerView()
                .padding([.top, .bottom], 8)
        }
    }
}

struct ActivityLast7DaysCell_Previews: PreviewProvider {
    static var previews: some View {
        ActivitySummaryLast7DaysCell()
            .mockEnvironment(weightUnit: .metric, isPro: true)
            .previewLayout(.sizeThatFits)
    }
}
