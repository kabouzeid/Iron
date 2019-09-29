//
//  PurchaseSheet.swift
//  Iron
//
//  Created by Karim Abou Zeid on 29.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct PurchaseSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    var body: some View {
        NavigationView {
            PurchaseView()
                .navigationBarTitle("Iron Pro", displayMode: .inline)
                .navigationBarItems(leading: Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

#if DEBUG
struct PurchaseSheet_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseSheet()
            .environmentObject(EntitlementStore.shared)
    }
}
#endif
