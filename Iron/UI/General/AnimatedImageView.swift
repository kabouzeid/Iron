//
//  AnimatedImageView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 06.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct AnimatedImageView : UIViewRepresentable {
    var uiImages: [UIImage]
    var duration: TimeInterval
    
    func makeUIView(context: UIViewRepresentableContext<AnimatedImageView>) -> UIView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.contentMode = .scaleAspectFit
        setImages(imageView: imageView)

        let view = UIView()
        view.addSubview(imageView)
        
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AnimatedImageView>) {
        let imageView = uiView.subviews.first as? UIImageView
        setImages(imageView: imageView!)
    }
    
    func setImages(imageView: UIImageView) {
        imageView.animationImages = uiImages
        imageView.animationDuration = duration
        imageView.startAnimating()
    }
}

#if DEBUG
struct ImageView_Previews : PreviewProvider {
    static var testImages: [UIImage] {
        guard let exercise = MockWorkoutData.metricRandom.workoutExercise.exercise(in: ExerciseStore.shared.exercises) else { return [] }
        var images = [UIImage]()
        for pdfPaths in exercise.pdfPaths {
            let url = Bundle.main.bundleURL.appendingPathComponent("everkinetic-data").appendingPathComponent(pdfPaths)
            if let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                images.append(image)
            }
        }
        return images
    }
    
    static var previews: some View {
        AnimatedImageView(uiImages: testImages, duration: 2)
    }
}
#endif
