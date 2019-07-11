//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

// only temporarily here, put this in the environment later so other views can use it
class SettingsStore: BindableObject {
    var didChange = PassthroughSubject<Void, Never>()
    
    enum WeightUnit: String, CaseIterable, Hashable {
        case metric
        case imperial
        
        var title: String {
            switch self {
            case .metric:
                return "Metric (kg)"
            case .imperial:
                return "Imperial (lb)"
            }
        }
    }
    
    var weightUnit: WeightUnit {
        get {
            UserDefaults.standard.weightUnit
        }
        set {
            UserDefaults.standard.weightUnit = newValue
            didChange.send()
        }
    }
}

struct SettingsView : View {
    @ObjectBinding private var settingsStore = SettingsStore()

    var body: some View {
        NavigationView {
            Form {
                Picker("Weight Unit", selection: $settingsStore.weightUnit) {
                    ForEach(SettingsStore.WeightUnit.allCases.identified(by: \.self)) { weightUnit in
                        Text(weightUnit.title).tag(weightUnit)
                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
        }
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
