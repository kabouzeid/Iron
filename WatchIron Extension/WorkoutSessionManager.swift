//
//  WorkoutSessionManager.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 05.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit
import Combine

class WorkoutSessionManagerStore: ObservableObject {
    static let shared = WorkoutSessionManagerStore()
    
    var objectWillChange = PassthroughSubject<Void, Never>()
    
    private var workoutSessionManagerWillChangeCancellable: Cancellable?
    
    private var _workoutSessionManager: WorkoutSessionManager? {
        didSet { // don't use willSet, somehow this is sometimes to early in this case
            workoutSessionManagerWillChangeCancellable = _workoutSessionManager?.objectWillChange
                .receive(on: DispatchQueue.main)
                .subscribe(objectWillChange)
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var workoutSessionManager: WorkoutSessionManager? {
        get {
            return _workoutSessionManager
        }
        set {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(WorkoutSessionManager.accessQueue))
            _workoutSessionManager = newValue
        }
    }
}

class WorkoutSessionManager: NSObject, ObservableObject {
    static let healthStore = HKHealthStore()
    
    var objectWillChange = ObservableObjectPublisher()
    
    private var _startDate: Date? {
        willSet {
            objectWillChange.send()
        }
    }
    var startDate: Date? {
        get {
            _startDate ?? workoutBuilder.startDate
        }
        set {
            assert(newValue != nil)
            if newValue != startDate {
                print("overwriting startDate=\(startDate?.description ?? "nil") with \(newValue?.description ?? "nil")")
                _startDate = newValue
            } else {
                print("keeping startDate=\(startDate?.description ?? "nil") new value would be \(newValue?.description ?? "nil")")
            }
        }
    }
    
    private var _endDate: Date? {
        willSet {
            objectWillChange.send()
        }
    }
    var endDate: Date? {
        get {
            _endDate ?? workoutBuilder.endDate
        }
        set {
            if newValue != endDate {
                print("overwriting endDate=\(endDate?.description ?? "nil") with \(newValue?.description ?? "nil")")
                _endDate = newValue
            } else {
                print("keeping endDate=\(endDate?.description ?? "nil") new value would be \(newValue?.description ?? "nil")")
            }
        }
    }
    
    let workoutSession: HKWorkoutSession
    private let workoutBuilder: HKLiveWorkoutBuilder
    
    init(session: HKWorkoutSession) {
        self.workoutSession = session
        self.workoutBuilder = session.associatedWorkoutBuilder()
        
        super.init()
        
        workoutSession.delegate = self
        workoutBuilder.delegate = self
    }
    
    // make sure everything that modifies the session or the builder runs on this serial queue
    static let accessQueue = DispatchQueue(label: "com.kabouzeid.workoutsessionmanagerqueue", qos: .userInitiated, target: .global(qos: .userInitiated))
    
    static func perform(_ block: @escaping () -> Void) {
        accessQueue.async {
            block()
        }
    }
    
    static func performAndWait(_ block: () -> Void) {
        accessQueue.sync {
            block()
        }
    }
    
    var state: HKWorkoutSessionState {
        return workoutSession.state
    }
    
    var uuid: UUID? {
        guard let uuidString = workoutBuilder.metadata[HKMetadataKeyExternalUUID] as? String else { return nil }
        return UUID(uuidString: uuidString)
    }
    
    func setUuid(_ uuid: UUID) throws {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            objectWillChange.send()
        }
        
        let uuidSemaphore = DispatchSemaphore(value: 0)
        var uuidError: Error?
        workoutBuilder.addMetadata([HKMetadataKeyExternalUUID : uuid.uuidString], completion: { (success, error) in
            defer { uuidSemaphore.signal() }
            if !success {
                uuidError = error ?? NSError()
            }
        })
        uuidSemaphore.wait()
        if let error = uuidError {
            throw error
        }
    }
    
    func updateStartDate(_ startDate: Date) throws {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // TODO safe the date in the workout meta data or shared prefs so it can be restored
        self.startDate = startDate
    }
    
    func updateEndDate(_ endDate: Date?) throws {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // TODO safe the date in the workout meta data or shared prefs so it can be restored
        self.endDate = endDate
    }
    
    func prepare() throws {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // prepare the workout
        workoutSession.prepare()
    }
    
    /**
     prepare() does not necessarily need to be called before
     */
    func start(start: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // request permissions
        do {
            try requestWorkoutPermissions().get()
        } catch {
            discard()
            completion(.failure(error))
            return
        }
        
        defer {
            objectWillChange.send()
        }
        
        workoutBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: Self.healthStore, workoutConfiguration: workoutSession.workoutConfiguration)
        workoutSession.startActivity(with: start)
        workoutBuilder.beginCollection(withStart: start, completion: { (success, error) in
            guard success else {
                self.discard()
                completion(.failure(error ?? NSError()))
                return
            }
            completion(.success(()))
        })
        
        print("collecting samples for \(workoutBuilder.dataSource?.typesToCollect.description ?? "nil")")
    }
    
    func discard() {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            objectWillChange.send()
        }
        
        workoutSession.end()
        workoutBuilder.discardWorkout()
    }
    
    func end(end: Date, completion: @escaping (Result<HKWorkout, Error>) -> Void) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            objectWillChange.send()
        }
        
        workoutSession.end()
        
        let endCollectionSemaphore = DispatchSemaphore(value: 0)
        var endCollectionError: Error?
        print("ending collection...")
        workoutBuilder.endCollection(withEnd: end, completion: { (success, error) in
            defer { endCollectionSemaphore.signal() }
            if !success {
                endCollectionError = error ?? NSError()
            }
        })
        endCollectionSemaphore.wait()
        if let error = endCollectionError {
            completion(.failure(error))
            return
        }
        print("ended collection")
        
        do {
            try self.requestWorkoutPermissions().get()
        } catch {
            self.discard()
            completion(.failure(error))
            return
        }
        
        workoutBuilder.finishWorkout(completion: { (workout, error) in
            guard let workout = workout else {
                completion(.failure(error ?? NSError()))
                return
            }

            if let _startDate = self._startDate, _startDate != workout.startDate {
                print("replacing saved workout because saved workout has startDate \(workout.startDate) but startDate has been updated to \(_startDate)")
                // the start date was updated while the workout was already running
                // replace the saved workout with a copy that has the correct start date
                
                let updatedWorkout = HKWorkout(activityType: workout.workoutActivityType, start: _startDate, end: workout.endDate, workoutEvents: workout.workoutEvents, totalEnergyBurned: workout.totalEnergyBurned, totalDistance: workout.totalDistance, device: workout.device, metadata: workout.metadata)

                Self.healthStore.save(updatedWorkout) { (success, error) in
                    guard success else {
                        completion(.failure(error ?? NSError()))
                        return
                    }
                    Self.healthStore.delete(workout) { (success, error) in
                        guard success else {
                            print(error.debugDescription)
                            return
                        }
                        completion(.success(updatedWorkout))
                    }
                }
            } else {
                completion(.success(workout))
            }
        })
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//        print(#function)
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
//        print(#function)
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print(#function + " \(toState.name)")
        
        objectWillChange.send()
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print(#function)
        
        objectWillChange.send()
        // TODO: notify phone about this
    }
}

// MARK: - Permissions
extension WorkoutSessionManager {
    private static func requestPermissions(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(NSError()))
            return
        }
        
        Self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                completion(.failure(error ?? NSError()))
                return
            }
            completion(.success(()))
        }
    }
    
    func requestWorkoutPermissions(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else { completion(.failure(NSError())); return }
        guard let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { completion(.failure(NSError())); return }
        let share: Set = [HKObjectType.workoutType()]
        let read = Set([heartRate, activeEnergyBurned])
        
        Self.requestPermissions(toShare: share, read: read, completion: completion)
    }
    
    private func requestWorkoutPermissions() -> Result<Void, Error> {
        let permissionSemaphore = DispatchSemaphore(value: 0)
        var permissionsResult: Result<Void, Error>?
        print("requesting permissions...")
        requestWorkoutPermissions { result in
            defer { permissionSemaphore.signal() }
            permissionsResult = result
        }
        permissionSemaphore.wait()
        print("permission request result: \(permissionsResult.debugDescription)")
        return permissionsResult ?? .failure(NSError())
    }
}

extension HKWorkoutSessionState {
    var name: String {
        switch self {
        case .ended:
            return "ended"
        case .notStarted:
            return "not started"
        case .paused:
            return "paused"
        case .prepared:
            return "prepared"
        case .running:
            return "running"
        case .stopped:
            return "stopped"
        @unknown default:
            fatalError()
        }
    }
}
