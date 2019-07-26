//
//  VisualEffectView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 02.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct VisualEffectView : UIViewRepresentable {
    var effect: UIVisualEffect
    
    func makeUIView(context: UIViewRepresentableContext<VisualEffectView>) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<VisualEffectView>) {
    }
}

#if DEBUG
struct VisualEffectView_Previews : PreviewProvider {
    static var previews: some View {
        VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
}
#endif
