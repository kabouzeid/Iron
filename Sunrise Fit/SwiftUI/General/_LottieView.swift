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
        Group {
            LottieDemoView(name: "exploding_star")
                .previewDisplayName("exploding_star")
        }
    }
}

private struct LottieDemoView: View {
    var name: String
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Button("Play Animation") {
                    self.animate = true
                }
            }
            if animate {
                _LottieView(name: name) { animationView in
                    animationView.play(fromFrame: 3, toFrame: 60) { _ in
                        self.animate = false
                    }
                }
                .animation(.basic())
            }
        }
    }
}
#endif
