//
//  AppState.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 06.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit
import Combine

class AppState: ObservableObject {
    static let shared = AppState()
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    private var workoutSessionCancellables = Set<AnyCancellable>()
    
    init() {
        PhoneConnectionManager.shared.isActivatedPublisher
            .receive(on: DispatchQueue.main)
            .map { _ in }
            .replaceError(with: ())
            .subscribe(self.objectWillChange)
            .store(in: &cancellables)
        
        PhoneConnectionManager.shared.isReachablePublisher
            .receive(on: DispatchQueue.main)
            .map { _ in }
            .replaceError(with: ())
            .subscribe(self.objectWillChange)
            .store(in: &cancellables)
    }
    
    var isActivated: Bool {
        PhoneConnectionManager.shared.isActivated
    }
    
    var isReachable: Bool {
        PhoneConnectionManager.shared.isReachable
    }
}

