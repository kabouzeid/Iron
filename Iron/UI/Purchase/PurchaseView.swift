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
    @EnvironmentObject private var entitlementsStore: EntitlementStore
    @ObservedObject private var storeManager = StoreManager.shared
    
    @State private var restoreResult: RestoreResult?
    private struct RestoreResult: Identifiable {
        let id = UUID()
        let success: Bool
        let error: Error?
    }
    
    private func alert(restoreResult: RestoreResult) -> Alert {
        if restoreResult.success {
            return Alert(title: Text("Restore Successful"))
        } else {
            let errorMessage = restoreResult.error?.localizedDescription
            return Alert(title: Text("Restore Failed"), message: errorMessage.map { Text($0) })
        }
    }
    
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
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 0)
                    
                    FeatureView(
                        image: Image(systemName: "waveform.path.ecg"),
                        imageColor: .blue,
                        title: Text("Charts"),
                        text: Text("View beautiful charts and analyze your progress over time.")
                    )
                    
                    FeatureView(
                        image: Image(systemName: "plus"),
                        imageColor: .green,
                        title: Text("Custom Exercises"),
                        text: Text("Create as many custom exercises as you want.")
                    )
                    
                    FeatureView(
                        image: Image(systemName: "heart.fill"),
                        imageColor: .red,
                        title: Text("Support the Development"),
                        text: Text("This ensures that I can focus on making Iron better every day.")
                    )
                    
                    Spacer().frame(height: 0)
                }
                .fixedSize(horizontal: false, vertical: true) // fixes bug where text gets truncated (iOS 13.3.1)
            }
            
            if storeManager.products == nil {
                HStack {
                    Spacer()
                    ActivityIndicatorView(style: .medium)
                    Spacer()
                }
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
                Button(action: {
                    StoreObserver.shared.restore()
                }) {
                    HStack {
                        Text("Restore Purchases")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }.disabled(!canMakePayments)
            
            Section {
                Button(action: {
                    if let url = URL(string: "https://ironapp.io/privacypolicy/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "hand.raised")
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://ironapp.io/tos/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "doc.plaintext")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear {
            self.storeManager.fetchProducts(matchingIdentifiers: IAPIdentifiers.pro)
        }
        .onReceive(NotificationCenter.default.publisher(for: .RestorePurchasesComplete)) { output in
            guard let success = output.userInfo?[restorePurchasesSuccessUserInfoKey] as? Bool else { return }
            self.restoreResult = RestoreResult(success: success, error: output.userInfo?[restorePurchasesErrorUserInfoKey] as? Error)
        }
        .alert(item: $restoreResult) { restoreResult in
            self.alert(restoreResult: restoreResult)
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
        VStack(alignment: .leading) {
            HStack {
                title
                image.foregroundColor(imageColor)
            }.font(.headline)
            text.lineLimit(Int.max)
        }
    }
}

private struct ProductCell: View {
    @ObservedObject var storeObserver = StoreObserver.shared
    
    let product: SKProduct
    
    let purchased: Bool
    
    private var transactionError: Binding<IdentifieableError?> {
        Binding(
            get: {
                guard let transaction = self.storeObserver.failedTransactions.first(where: { $0.payment.productIdentifier == self.product.productIdentifier }) else { return nil }
                let error = transaction.error
                if let error = error as? SKError, error.code == .paymentCancelled { return nil } // this is not really an error, ignore it
                return IdentifieableError(error: error, id: transaction.hash)
            },
            set: { newValue in
                guard newValue == nil else { return }
                self.storeObserver.failedTransactions.removeAll { $0.payment.productIdentifier == self.product.productIdentifier }
            }
        )
    }
    
    private struct IdentifieableError: Identifiable {
        let error: Error?
        let id: Int
    }
    
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
    
    enum State {
        case `default`
        case processing
        case waitingForParentApproval
    }
    private var state: State {
        let relevantTransactions = storeObserver.pendingTransactions.filter { $0.payment.productIdentifier == product.productIdentifier }
        if relevantTransactions.contains(where: { $0.transactionState == .deferred }) {
            return .waitingForParentApproval
        } else if relevantTransactions.contains(where: { $0.transactionState == .purchasing || $0.transactionState == .purchased || $0.transactionState == .restored }) {
            return .processing
        } else {
            // in this we either have no relevant pending transactions, or .failed, but it's unlikely because those transactions are immediately removed
            return .default
        }
    }
    
    @ViewBuilder
    private var buttonLabel: some View {
        if state == .processing {
            ActivityIndicatorView(style: .medium)
        } else {
            Text(buttonText).fontWeight(.semibold)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.localizedTitle)
                if state == .waitingForParentApproval {
                    Text("Waiting for approval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                self.storeObserver.buy(product: self.product)
            }) {
                buttonLabel
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 6)
                    .background(
                        RoundedRectangle(cornerRadius: 100, style: .circular) // cornerRadius is arbitrary
                            .foregroundColor(Color(.systemFill)) // mimic the App Store
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(purchased || state == .processing)
        }
        .padding([.top, .bottom], 8)
        .alert(item: transactionError) { transactionError in
            Alert(title: Text("Transaction Failed"), message: transactionError.error.map { Text($0.localizedDescription) })
        }
    }
}

struct ActivityIndicatorView: UIViewRepresentable {
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: style)
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        // nothing to be done
    }
    
    static func dismantleUIView(_ uiView: UIActivityIndicatorView, coordinator: ()) {
        uiView.stopAnimating()
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
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
