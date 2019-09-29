//
//  PurchaseView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine
import StoreKit

struct PurchaseView: View {
    @ObservedObject private var storeManager = StoreManager.shared // should go in the environment later
    @ObservedObject private var entitlementsStore = EntitlementsStore.shared // should go in the environment later
    
    private var canMakePayments: Bool {
        StoreObserver.shared.canMakePayments
    }
    
    private var hasProLifetime: Bool {
        entitlementsStore.entitlements.contains(IAPIdentifiers.proLifetime)
    }
    
    private var proLifetimeProduct: SKProduct? {
        storeManager.products?.first { $0.productIdentifier == IAPIdentifiers.proLifetime }
    }
    
    private var proMonthlyProduct: SKProduct? {
        storeManager.products?.first { $0.productIdentifier == IAPIdentifiers.proMonthly }
    }
    
    private var proYearlyProduct: SKProduct? {
        storeManager.products?.first { $0.productIdentifier == IAPIdentifiers.proYearly }
    }
    
    private var subscriptionInfoText: String? {
        "After the 1 week free trial your subscription automatically renews and your iTunes Account will be charged for the upcoming period unless you cancel the subscription at least 24 hours before the end of the trial period. You can cancel your subscription at any time."
    }
    
    private var subscriptionInfo: some View {
        Text(subscriptionInfoText ?? "")
    }
    
    var body: some View {
        List {
            Section {
                FeatureView(
                    image: Image(systemName: "waveform.path.ecg"),
                    imageColor: .blue,
                    title: Text("Charts"),
                    text: Text("View beautiful charts and analyze your progress over time.")
                ) // TODO show chart here
                
                FeatureView(
                    image: Image(systemName: "plus"),
                    imageColor: .green,
                    title: Text("Custom Exercises"),
                    text: Text("Some of your exercises are missing in Iron? No problem, create as many custom exercises as you want.")
                )
                
                FeatureView(
                    image: Image(systemName: "heart.fill"),
                    imageColor: .red,
                    title: Text("Support the Development"),
                    text: Text("This ensures that I can focus on making Iron better every day.")
                )
            }
            
            proLifetimeProduct.map {
                ProductCell(
                    product: $0,
                    purchased: hasProLifetime
                ).disabled(!canMakePayments)
            }
            
            Section(footer: subscriptionInfo) {
                proMonthlyProduct.map {
                    ProductCell(
                        product: $0,
                        purchased: entitlementsStore.entitlements.contains($0.productIdentifier)
                    ).disabled(hasProLifetime)
                }
                
                proYearlyProduct.map {
                    ProductCell(
                        product: $0,
                        purchased: entitlementsStore.entitlements.contains($0.productIdentifier)
                    ).disabled(hasProLifetime)
                }
                
                Button("Manage Subscriptions") {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url, options: [:])
                    }
                }
            }.disabled(!canMakePayments)
            
            Section {
                Button("Restore Purchases") {
                    StoreObserver.shared.restore()
                }
            }.disabled(!canMakePayments)
            
            Section {
                Button("Terms of Service") {
                    if let url = URL(string: "https://kabouzeid.com/iron_tos.html") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Button("Privacy Policy") {
                    if let url = URL(string: "https://kabouzeid.com/iron_privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear {
            self.storeManager.fetchProducts(matchingIdentifiers: [IAPIdentifiers.proMonthly])
        }
        .navigationBarTitle("Iron Pro")
    }
}

private struct FeatureView: View {
    let image: Image
    var imageColor: Color? = nil
    let title: Text
    let text: Text
    
    var body: some View {
        HStack(alignment: .center) {
            image.padding().foregroundColor(imageColor)
            VStack(alignment: .leading) {
                title.font(.headline)
                text
            }
        }
    }
}

private struct ProductCell: View {
    let product: SKProduct
    
    let purchased: Bool
    
    private var buttonText: String {
        if purchased {
            if isSubscription {
                return "Active"
            } else {
                return "Purchased"
            }
        } else {
            guard let localPrice = product.localizedPrice else {
                return isSubscription ? "Subscribe" : "Buy"
            }
            guard let subscriptionPeriod = product.subscriptionPeriod else {
                return localPrice
            }
            return localPrice + " / " + subscriptionPeriod.text
        }
    }
    
    private var isSubscription: Bool {
        product.subscriptionPeriod != nil
    }
    
    var body: some View {
        HStack {
            Text(product.localizedTitle)
            Spacer()
            
            Button(action: {
                StoreObserver.shared.buy(product: self.product)
            }) {
                Text(buttonText)
                    .fontWeight(.semibold)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 6)
                    .background(
                        RoundedRectangle(cornerRadius: 100, style: .circular) // cornerRadius is arbitrary
                            .foregroundColor(Color(.systemFill)) // mimic the App Store
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(purchased)
        }
        .padding([.top, .bottom], 8)
    }
}

extension SKProductSubscriptionPeriod {
    var text: String {
        switch unit {
        case .day:
            return numberOfUnits > 1 ? "\(numberOfUnits) Days" : "Day"
        case .month:
            return numberOfUnits > 1 ? "\(numberOfUnits) Months" : "Month"
        case .week:
            return numberOfUnits > 1 ? "\(numberOfUnits) Weeks" : "Week"
        case .year:
            return numberOfUnits > 1 ? "\(numberOfUnits) Years" : "Year"
        @unknown default:
            fatalError()
        }
    }
}

#if DEBUG
struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseView()
    }
}
#endif
