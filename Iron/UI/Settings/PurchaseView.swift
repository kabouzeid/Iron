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
    @ObservedObject private var proStatusStore = EntitlementsStore.shared // should go in the environment later
    
    private var proMonthlyProduct: SKProduct? {
        storeManager.products?.first { $0.productIdentifier == IAPIdentifiers.proMonthly }
    }
    
    private var expirationDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }
    
    var body: some View {
        List {
            Section(header:
                Text("is pro: \(proStatusStore.isPro ? "Yes" : "No")")
            ) {
                proMonthlyProduct.map {
                    ProductCell(product: $0)
                }
            }
            
            Section {
                Button("Restore Purchases") {
                    StoreObserver.shared.restore()
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

private struct ProductCell: View {
    let product: SKProduct
    
    var body: some View {
        HStack {
            Text(product.localizedTitle)
            Spacer()
            Button(action: {
                StoreObserver.shared.buy(product: self.product)
            }) {
                Text(product.localizedPrice ?? "Subscribe")
                    .fontWeight(.semibold)
                    .padding([.leading, .trailing], 12)
                    .padding([.top, .bottom], 6)
                    .background(
                        RoundedRectangle(cornerRadius: 100, style: .circular) // cornerRadius is arbitrary
                            .foregroundColor(Color(.systemFill)) // mimic the App Store
                )
            }
            .buttonStyle(BorderlessButtonStyle())
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
