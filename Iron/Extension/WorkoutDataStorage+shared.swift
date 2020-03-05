//
//  WorkoutDataStorage+shared.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit
import CoreData
import Combine

extension WorkoutDataStorage {
    private static var cancellables = Set<AnyCancellable>()
    
    private static var startChangedSubject = PassthroughSubject<(Date, UUID), Never>()
    private static var endChangedSubject = PassthroughSubject<(Date?, UUID), Never>()
    
    static let shared: WorkoutDataStorage = {
        let workoutDataStorage = WorkoutDataStorage(storeDescription: .init(url: groupStoreURL))
        workoutDataStorage.persistentContainer.viewContext.publisher
            .drop { _ in IronBackup.restoringBackupData } // better to ignore the spam while we are restoring
            .sink { changes in
                WorkoutDataStorage.sendObjectsWillChange(changes: changes)
                for changedObject in changes.updated {
                    if let workout = changedObject as? Workout, !workout.isFault, let uuid = workout.uuid {
                        // TODO: update stored health workout if not current workout
                        if workout.isCurrentWorkout {
                            if uuid == WatchConnectionManager.shared.currentWatchWorkoutUuid {
                                if changedObject.changedValuesForCurrentEvent()["start"] != nil, let start = workout.start {
                                    startChangedSubject.send((start, uuid))
                                }
                                if changedObject.changedValuesForCurrentEvent()["end"] != nil {
                                    endChangedSubject.send((workout.end, uuid))
                                }
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        startChangedSubject
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink {
                WatchConnectionManager.shared.updateWatchWorkoutStart(start: $0.0, uuid: $0.1)
            }
            .store(in: &cancellables)
        
        endChangedSubject
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink {
                WatchConnectionManager.shared.updateWatchWorkoutEnd(end: $0.0, uuid: $0.1)
            }
            .store(in: &cancellables)
        
        return workoutDataStorage
    }()
}
