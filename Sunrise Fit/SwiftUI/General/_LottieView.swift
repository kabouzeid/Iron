//
//  _LottieView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 07.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Lottie

struct _LottieView : UIViewRepresentable {
    var name: String
    var update: (AnimationView) -> Void

    func makeUIView(context: UIViewRepresentableContext<_LottieView>) -> AnimationView {
        AnimationView(animation: Lottie.Animation.named(name, subdirectory: "lottie"))
    }
    
    func updateUIView(_ uiView: AnimationView, context: UIViewRepresentableContext<_LottieView>) {
        update(uiView)
    }
}

#if DEBUG
struct LottieView_Previews : PreviewProvider {
    static var previews: some View {
        _LottieView(name: "exploding_star") { animationView in
            animationView.play(fromFrame: 3, toFrame: 60)
        }
    }
}
#endif
