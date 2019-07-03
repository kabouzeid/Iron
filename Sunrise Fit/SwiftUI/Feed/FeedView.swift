//
//  FeedView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct FeedView : View {
    let pinnedCharts = UserDefaults.standard.pinnedCharts() // TODO: create bindable object for refresh

    var body: some View {
        return NavigationView {
            List {
                Section {
                    ActivityChartViewCell()
                    FeedBannerView()
                }
                
                Section {
                    ForEach(pinnedCharts) { chart in
                        PinnedChartViewCell(pinnedChart: chart)
                    }
                    PresentationLink(destination:
                        // TODO: present actual view to choose exercise
                        Text("Placeholder")
                    ) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Widget")
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationBarTitle(Text("Feed"))
        }
    }
}

#if DEBUG
struct FeedView_Previews : PreviewProvider {
    static var previews: some View {
        FeedView().environmentObject(mockTrainingsDataStore)
    }
}
#endif
