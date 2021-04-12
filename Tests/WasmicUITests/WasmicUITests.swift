//
//  WasmicUITests.swift
//  WasmicUITests
//
//  Created by kateinoigakukun on 2021/04/12.
//

import XCTest

class WasmicUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["-isWelcomeDone", "true"]
        setupSnapshot(app)
        app.launch()
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSnapshots() throws {
        app.tabBars.buttons["Recents"].tap()
        app.tabBars.buttons["Browse"].tap()
        let navigationBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        if app.collectionViews.cells.count > 1 {
            navigationBar.buttons["DOC.itemCollectionMenuButton.Ellipsis"].tap()
            let selectButton = app.collectionViews.buttons["Select"]
            selectButton.tap()
            navigationBar.buttons["Select All"].tap()
            app.toolbars["Toolbar"].buttons["Delete"].tap()
        }

        navigationBar
            .buttons["FullDocumentManagerViewControllerNavigationBarCreateButtonIdentifier"]
            .tap()
        let editorView = app.textViews.element
        editorView.clearText(app: app)
        editorView.tap()
        editorView.typeText("""
        (module
         (export "fib" (func $fib))
         (func $fib (param $n i32) (result i32)
          (if
           (i32.lt_u
            (get_local $n)
            (i32.const 2)
           )
           (return
            (get_local $n)
           )
          )
          (return
           (i32.add
            (call $fib
             (i32.sub
              (get_local $n)
              (i32.const 2)
             )
            )
            (call $fib
             (i32.sub
              (get_local $n)
              (i32.const 1)
             )
            )
           )
          )
         )
        )
        """)
        app.navigationBars.buttons["close"].tap()
        let mainCell = app.collectionViews.cells
            .element(matching: NSPredicate(format: "label CONTAINS %@", "main"))
        XCTAssertTrue(mainCell.waitForExistence(timeout: 1))
        mainCell.tap()
        app.textViews.element.tap()
        snapshot("01CodeEditor")

        app.navigationBars.buttons["Play"].tap()
        let argument0 = app.tables.textFields["Argument #0 (i32)"]
        argument0.tap()
        argument0.typeText("10")
        snapshot("02Invocation")

        app.buttons["Run"].tap()
        snapshot("03Execution")
        app.navigationBars["Execution"].buttons["Done"].tap()
    }
}

extension XCUIElement {
    func clearText(app: XCUIApplication) {
        tap()
        _ = app.wait(for: .unknown, timeout: 1)
        tap()
        let selectAll = app.menuItems["Select All"]
        XCTAssertTrue(selectAll.waitForExistence(timeout: 3))
        selectAll.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 1)
        self.typeText(deleteString)
    }
}
