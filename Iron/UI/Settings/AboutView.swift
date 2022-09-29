//
//  AboutView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 04.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            HStack {
                Image("AppIconRounded")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Iron \(versionString)")
                        .font(.headline)
                    
                    Text("by Karim Abou Zeid")
                        .font(.subheadline)
                }
                .padding()
            }
            .listRowBackground(Color.clear)
            
            Section {
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://github.com/kabouzeid/Iron")!)
                }) {
                    if #available(iOS 14.0, *) {
                        Label("Source Code", image: "github.fill")
                    } else {
                        HStack {
                            Image("github.fill")
                            Text("Source Code")
                        }
                    }
                }
                
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://twitter.com/kacodes")!)
                }) {
                    if #available(iOS 14.0, *) {
                        Label("@kacodes", image: "twitter.fill")
                    } else {
                        HStack {
                            Image("twitter.fill")
                            Text("@kacodes")
                        }
                    }
                }
                
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://ka.codes")!)
                }) {
                    if #available(iOS 14.0, *) {
                        Label("Website", systemImage: "globe")
                    } else {
                        HStack {
                            Image(systemName: "globe")
                            Text("Website")
                        }
                    }
                }
            }
            
            Section {
                Button {
                    UIApplication.shared.open(URL(string: "https://iron.ka.codes/privacy.html")!)
                } label: {
                    if #available(iOS 14.0, *) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    } else {
                        HStack {
                            Image("hand.raised")
                            Text("Privacy Policy")
                        }
                    }
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
            AboutView().mockEnvironment(weightUnit: .metric)
        }
    }
}
