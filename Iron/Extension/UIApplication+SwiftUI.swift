//
//  UIApplication+SwiftUI.swift
//  Iron
//
//  Created by Karim Abou Zeid on 23.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UIApplication {
    var activeSceneKeyWindow: UIWindow? {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
    }
}
