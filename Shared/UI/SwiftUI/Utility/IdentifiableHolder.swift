//
//  IdentifiableHolder.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct IdentifiableHolder<Value>: Identifiable {
     let id = UUID()
     let value: Value
 }
