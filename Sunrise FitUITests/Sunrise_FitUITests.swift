//
//  Rhino_FitUITests.swift
//  Rhino FitUITests
//
//  Created by Karim Abou Zeid on 12.05.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import XCTest

class Sunrise_FitUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSaveTraining() {

        let app = XCUIApplication()
        app.buttons["Start Training"].tap()
        app.navigationBars["Training"].buttons["Add"].tap()

        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Air Bike"]/*[[".cells.staticTexts[\"Air Bike\"]",".staticTexts[\"Air Bike\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.navigationBars["Abdominals"].buttons["Add"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Bent Knee Hip Raise"]/*[[".cells.staticTexts[\"Bent Knee Hip Raise\"]",".staticTexts[\"Bent Knee Hip Raise\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Bent Knee Hip Raise"]/*[[".cells.staticTexts[\"Bent Knee Hip Raise\"]",".staticTexts[\"Bent Knee Hip Raise\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Next Exercise"].tap()

        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Complete Set"].tap()
        app.buttons["Finish Training"].tap()

        app.navigationBars["Abdominals"].buttons["Save"].tap()

        app.tabBars.buttons["Profile"].tap()

        XCTAssertTrue(app.tables.staticTexts["Abdominals"].exists, "Training was not saved")
        XCTAssertTrue(app.tables.staticTexts.element(matching: NSPredicate(format: "label beginswith %@", "Today")).exists, "Training was not saved")
    }
    
}
