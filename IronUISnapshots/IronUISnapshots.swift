//
//  IronUISnapshots.swift
//  IronUISnapshots
//
//  Created by Karim Abou Zeid on 01.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import XCTest

class IronUISnapshots: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSnapshots() {
        let app = XCUIApplication()
        
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Feed"].tap()
        snapshot("01_Feed")
        
        tabBarsQuery.buttons["History"].tap()
        snapshot("02_History")
        
        let tablesQuery = app.tables
//        let firstWorkout = tablesQuery.buttons.firstMatch
//        if firstWorkout.exists {
//            snapshot("03_History_Item")
//        }
        
        tabBarsQuery.buttons["Workout"].tap()
        snapshot("04_Workout")
        
        tabBarsQuery.buttons["Exercises"].tap()
        snapshot("05_Exercises")
        
        tablesQuery.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chest" as NSString)).firstMatch.tap()
        tablesQuery.buttons["Bench Press: Barbell"].tap()
        snapshot("06_BenchPress")
        
//        let rowCableSeatedNavigationBar = app.navigationBars["Bench Press: Barbell"]
//        rowCableSeatedNavigationBar.buttons["waveform.path.ecg"].tap()
//        snapshot("07_Stats")
    }
}
