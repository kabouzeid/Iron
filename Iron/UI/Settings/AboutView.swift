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
        Form {
            Section(
                header:
                HStack {
                    Spacer()

                    Image("rounded_app_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)

                    VStack(alignment: .leading) {
                        Text("Iron \(versionString)").font(.headline)
                        if entitlementsStore.isPro {
                            Text("Pro Version")
                        }
                        Text("by Karim Abou Zeid")
                    }.padding()

                    Spacer()
                }.padding()
            ) {
                Button(action: {
                    guard let url = URL(string: "https://twitter.com/theironapp") else { return }
                    UIApplication.shared.open(url)
                }) {
                    HStack {
                        Text("Follow @theironapp")
                        Spacer()
                        Image("twitter")
                    }
                }
                
                Button(action: {
                    guard let url = URL(string: "https://twitter.com/swiftkarim") else { return }
                    UIApplication.shared.open(url)
                }) {
                    HStack {
                        Text("Follow @swiftkarim")
                        Spacer()
                        Image("twitter")
                    }
                }
            }
        }.navigationBarTitle("About", displayMode: .inline)
    }
    
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
//        return "\(version ?? "?") (\(build ?? "?"))"
        return "\(version ?? "?")"
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView().mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
