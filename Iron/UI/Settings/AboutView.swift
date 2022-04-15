//
//  AboutView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 04.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var entitlementsStore: EntitlementStore
    
    var body: some View {
        List {
            HStack {
                Image("rounded_app_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Iron \(versionString)")
                        .font(.headline)
                    
                    if entitlementsStore.isPro {
                        Text("Pro Version")
                            .font(.subheadline)
                    }
                    
                    Text("by Karim Abou Zeid")
                        .font(.subheadline)
                }
                .padding()
            }
            .listRowBackground(Color.clear)
            
            Section {
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://twitter.com/theironapp")!)
                }) {
                    Label("Follow @theironapp", systemImage: "eyes")
                }
                
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://twitter.com/kacodes")!)
                }) {
                    Label("Follow @kacodes", systemImage: "eyes")
                }
            }
            
            Section {
                Button {
                    UIApplication.shared.open(URL(string: "https://ironapp.io/privacypolicy")!)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
        }
        .navigationBarTitle("About", displayMode: .inline)
    }
    
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        #if DEBUG
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return "\(version ?? "?") (\(build ?? "?")) DEBUG"
        #else
        return "\(version ?? "?")"
        #endif
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView().mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
