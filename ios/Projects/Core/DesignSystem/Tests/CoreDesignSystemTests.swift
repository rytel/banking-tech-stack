import XCTest
@testable import CoreDesignSystem

final class CoreDesignSystemTests: XCTestCase {
    func test_accentColorIsDefined() {
        XCTAssertNotNil(AppColors.accent)
    }
}
