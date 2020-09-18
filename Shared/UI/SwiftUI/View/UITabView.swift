//
//  UITabView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct UITabView: UIViewControllerRepresentable {
    let viewControllers: [UIViewController]
    let selection: Int
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<UITabView>) -> UITabBarController {
        let tabController = UITabBarController()
        tabController.viewControllers = viewControllers
        tabController.selectedIndex = selection
        return tabController
    }
    
    func updateUIViewController(_ uiViewController: UITabBarController, context: UIViewControllerRepresentableContext<UITabView>) {
        uiViewController.selectedIndex = selection
    }
}

extension View {
    func hostingController() -> UIHostingController<Self> {
        UIHostingController(rootView: self)
    }
}

extension UIViewController {
    func tabItem(title: String?, image: UIImage?, tag: Int) -> Self {
        tabBarItem = .init(title: title, image: image, tag: tag)
        return self
    }
}

#if DEBUG
struct UITabView_Previews: PreviewProvider {
    static var previews: some View {
        UITabView(viewControllers: [
            Text("Tab A")
                .hostingController()
                .tabItem(title: "Tab A", image: UIImage(systemName: "a.circle"), tag: 0),
            
            Text("Tab B")
                .hostingController()
                .tabItem(title: "Tab B", image: UIImage(systemName: "b.circle"), tag: 1),
        ], selection: 1)
        .edgesIgnoringSafeArea([.top, .bottom])
    }
}
#endif
