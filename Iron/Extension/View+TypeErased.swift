//
//  View+TypeErased.swift
//  Iron
//
//  Created by Karim Abou Zeid on 14.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension View {
  public var typeErased: AnyView { AnyView(self) }
}
