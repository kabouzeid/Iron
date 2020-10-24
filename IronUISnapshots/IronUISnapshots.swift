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
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        
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
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            app.swipeUp()
            snapshot("02_Feed")
        }

        tabBarsQuery.buttons["History"].tap()
        if UIDevice.current.userInterfaceIdiom != .pad {
            snapshot("03_History")
        }
        app.tables.buttons.firstMatch.tap()
        snapshot("04_History_Item")
        
        tabBarsQuery.buttons["Workout"].tap()
        if UIDevice.current.userInterfaceIdiom != .pad {
            snapshot("05_Workout")
        }
        app.tables.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Biceps Curl" as NSString)).firstMatch.tap()
        snapshot("06_Workout_Item")
        
        tabBarsQuery.buttons["Exercises"].tap()
        if UIDevice.current.userInterfaceIdiom != .pad {
            snapshot("07_Exercises")
        }
        
        app.tables.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Chest" as NSString)).firstMatch.tap()
        app.tables.buttons["Bench Press: Barbell"].tap()
        snapshot("08_BenchPress")
    }
}
