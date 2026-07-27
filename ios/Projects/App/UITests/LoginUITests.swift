import XCTest

/// Drives the real app in the Simulator through `XCUIApplication`, so — unlike every other
/// test target in this repo — these hit the actual backend over the network instead of a mock.
/// The backend must be running locally before this target runs:
/// `cd backend && ./scripts/gen-cert.sh && go run ./cmd/server`.
///
/// XCTest, not Swift Testing: `XCUIApplication` launch/query APIs and `waitForExistence` are
/// XCTest idioms, and UI test bundles are a different animal from the unit test targets the
/// Swift-Testing-vs-XCTest split in the other modules is about.
@MainActor
final class LoginUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func test_loginScreen_showsUsernameAndPasswordFields() {
        XCTAssertTrue(app.staticTexts["Log in"].exists)
        XCTAssertTrue(app.textFields["usernameField"].exists)
        XCTAssertTrue(app.secureTextFields["passwordField"].exists)
    }

    func test_loginButton_isDisabledUntilBothFieldsAreFilled() {
        let loginButton = app.buttons["loginButton"]
        XCTAssertFalse(loginButton.isEnabled)

        app.textFields["usernameField"].tap()
        app.textFields["usernameField"].typeText("demo")
        XCTAssertFalse(loginButton.isEnabled)

        app.secureTextFields["passwordField"].tap()
        app.secureTextFields["passwordField"].typeText("demo1234")
        XCTAssertTrue(loginButton.isEnabled)
    }

    func test_validCredentials_navigateToTopics() {
        login(username: "demo", password: "demo1234")

        XCTAssertTrue(app.staticTexts["topicsTitle"].waitForExistence(timeout: 5))
    }

    func test_invalidCredentials_showsErrorMessageAndStaysOnLogin() {
        login(username: "demo", password: "wrong-password")

        XCTAssertTrue(app.staticTexts["loginErrorMessage"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["loginButton"].exists)
        XCTAssertFalse(app.staticTexts["topicsTitle"].exists)
    }

    private func login(username: String, password: String) {
        let usernameField = app.textFields["usernameField"]
        usernameField.tap()
        usernameField.typeText(username)

        let passwordField = app.secureTextFields["passwordField"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["loginButton"].tap()
    }
}
